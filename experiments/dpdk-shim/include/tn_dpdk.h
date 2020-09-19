#pragma once

#include "env/pci.h"
#include "net/network.h"


#define TN_DPDK_DEVICES_MAX_COUNT 3

struct tn_dpdk_device
{
	struct tn_net_device* device;
	struct tn_net_agent* agent;
	bool is_promiscuous;
	bool is_processing;
#ifndef ASSUME_ONE_WAY
	bool current_outputs[TN_DPDK_DEVICES_MAX_COUNT];
#endif
	uint8_t buffer[64]; // must be large enough for struct rte_mbuf to fit in there
};

extern struct tn_dpdk_device tn_dpdk_devices[TN_DPDK_DEVICES_MAX_COUNT];

extern struct tn_pci_address tn_dpdk_pci_addresses[TN_DPDK_DEVICES_MAX_COUNT];

extern uint16_t tn_dpdk_devices_count;
