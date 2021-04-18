/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  TYPE_TCP  = 6;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
    bit<32> flow_hash;
    bit<48> flow_tstamp;
    bit<48> flow_tstamp_previous;
    bit<48> time_now;
    bit<48> time_diff;
    bit<10> microsecs;
    bit<10> millisecs;
    bit<8>  diff_repr;
    bit<4>  micro_hex;
    bit<4>  milli_hex;
    bit<8>  inc_diff_repr;
    bit<48> inc_time_diff;
    bit<16> inc_milli;
    bit<16> inc_micro;
    bit<48> jitter;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_TCP: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    /* index: flow hash, value: last timestamp */
    register<bit<48>>(8192) tstamp_register;

    // Calculating time_diff
    action calc_time_diff(){
        // Use built-in metadata for timestamps, given in microseconds
        meta.time_now = standard_metadata.ingress_global_timestamp;

        // If timestamp of previous is zero, let time_diff be 0
        if (meta.flow_tstamp == 0) {
            meta.time_diff = 0;
        } else {
            // Else if not zero, assume current time is larger than previous and get difference
            meta.time_diff = meta.time_now - meta.flow_tstamp;
        }
        // Set stored timestamp as previous and update to be current timestamp
        meta.flow_tstamp_previous = meta.flow_tstamp;
        meta.flow_tstamp = meta.time_now;

        // Bit-slice to get bits containing milli and microseconds
        // Causes some loss of information as time_diff increases
        meta.millisecs = meta.time_diff[19:10];
        meta.microsecs = meta.time_diff[9:0];

        // All millisec-values <= 15 can be directly represented
        // All millisec-values > 15 will be represented as 15, can be interpreted as significant time_diff
        if (meta.millisecs <= 15) {
            meta.milli_hex = (bit<4>) meta.millisecs;
        } else {
            meta.milli_hex = (bit<4>) 15;
        }
        // produces intervals of 64, starting at 0 and going up to 1000'ish
        meta.micro_hex = (bit<4>) (meta.microsecs / 64);

        // Produce a composite of each value
        // To check: Slice and multiply microseconds with 64
        // Lower bound: micro * 64
        // Upper bound: (micro * 64) + 63
        meta.diff_repr[7:4] = meta.milli_hex;
        meta.diff_repr[3:0] = meta.micro_hex;

        // Set the TOS/diffserv field to be the difference representation
        hdr.ipv4.diffserv = meta.diff_repr;
    }

    action store_time_diffs() {
        // reverse representation to get approximate time_diff from other switch
        meta.inc_milli = (bit<16>) meta.inc_diff_repr[7:4];
        meta.inc_micro = (bit<16>) meta.inc_diff_repr[3:0];
        meta.inc_time_diff = (bit<48>) ((meta.inc_milli * 1000) + (meta.inc_micro * 64));

        // Write crucial information to switch logs for further processing
        log_msg("TIMEDIFFS: flow_hash={}, ip_src={}, time_diff={}, inc_time_diff={}",
                {meta.flow_hash, hdr.ipv4.srcAddr, meta.time_diff, meta.inc_time_diff}
        );
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    // Basic forwarding logic
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
        if (hdr.tcp.isValid()) {
            @atomic {
                hash(meta.flow_hash,
                    HashAlgorithm.crc16,
                    (bit<32>)0,
                    { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
                    (bit<32>) 8192);

                // Ensure import variables are 0 for any given packet
                meta.millisecs = 0;
                meta.microsecs = 0;
                meta.diff_repr = 0;
                meta.flow_tstamp = 0;                   // Explicitly set to 0 to ensure correct calculation
                meta.inc_diff_repr = hdr.ipv4.diffserv;

                // Read the previously stored timestamp
                tstamp_register.read(meta.flow_tstamp, (bit<32>) meta.flow_hash);
                // Calculate time difference between previous and current
                calc_time_diff();
                // Store the current timestamp
                tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp);

                // If TOS/diffserv field is not 0, assume it's used for time_diff
                if (meta.inc_diff_repr > 0) {
                    store_time_diffs();
                }
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
        // If checksum is valid, update with the following fields
	    hdr.ipv4.isValid(),
        { hdr.ipv4.version,
          hdr.ipv4.ihl,
          hdr.ipv4.diffserv,
          hdr.ipv4.totalLen,
          hdr.ipv4.identification,
          hdr.ipv4.flags,
          hdr.ipv4.fragOffset,
          hdr.ipv4.ttl,
          hdr.ipv4.protocol,
          hdr.ipv4.srcAddr,
          hdr.ipv4.dstAddr },
        // Update the checksum if the header is valid
        hdr.ipv4.hdrChecksum,
        // Update with the following algorithm
        HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
