# APB CAN Bridge – Verification Architecture

Reference: `APB CAN ARCHITECTURE.png` (APB CAN BRIDGE ARCHITECTURE).
DUT: `can_controller_top` (CAN 2.0B controller with APB4 slave port), see the design specification.

## Hierarchy

```
apb_can_top                                   (src/dv/apb_can_top.sv)
├── node[i]  (i = 0 .. `NO_OF_NODES-1)
│   ├── apb_if                                (APB AVIP)  APB INTERFACE[N]
│   ├── apb_master_agent_bfm #(NODE_ID=i)     (APB AVIP)  APB_HDL_AVIP / APB_MASTER_AGENT_BFM[]
│   │   ├── apb_master_driver_bfm
│   │   └── apb_master_monitor_bfm
│   ├── can_interface                                      CAN INTERFACE[N]
│   ├── can_controller_top (dut)              (src/rtl)    DUT[N]
│   └── apb_can_assertion
├── can_bus  (interface/can_bus.sv)                        CAN_BUS (wired-AND of all can_tx)
└── run_test()
      apb_can_base_test                                    APB_CAN_TEST
      └── apb_can_env_h : apb_can_environment              APB_CAN_ENVIRONMENT
          ├── apb_can_virtual_seqr_h                       APB_CAN_VIRTUAL_SEQUENCER[]
          ├── per node [i]:
          │   ├── apb_can_reg_model_h[i] : can_reg_block   APB_CAN_REG_MODEL[] (27 registers + ADDRESS MAP)
          │   │                           (src/dv/ral/)
          │   ├── apb_environment_h[i] : apb_environment   APB_HVL_AVIP / APB_ENVIRONMENT[]
          │   │   ├── apb_master_agent_h[i] (APB AVIP)     APB_MASTER_ACTIVE_AGENT
          │   │   │   ├── apb_master_agent_config          APB_MASTER_AGENT_CONFIG
          │   │   │   ├── apb_master_sequencer             APB_MASTER_SEQUENCER
          │   │   │   ├── apb_master_driver_proxy          APB_MASTER_DRIVER_PROXY
          │   │   │   └── apb_master_monitor_proxy         APB_MASTER_MONITOR_PROXY
          │   │   ├── apb_reg2bus_adapter_h                APB_ADAPTER (reg2bus)
          │   │   ├── apb_predictor_h                      APB_PREDICTOR
          │   │   └── apb_bus2reg_adapter_h                APB_ADAPTER (bus2reg)
          │   ├── can_passive_agent                        CAN_PASSIVE_AGENT[]
          │   │   └── can_passive_monitor
          │   ├── apb_can_scoreboard                       APB_CAN_SCOREBOARD[]
          │   └── apb_can_subscriber                       APB_CAN_SUBSCRIBER[]
          └── (sequences)
              apb_can_virtual_base_sequence              APB_CAN_VIRTUAL_SEQUENCE[]
              apb_can_base_sequence (uvm_reg_sequence)   APB_CAN_SEQUENCE[]
```

## Connections

| From | To | Kind |
|------|----|------|
| `apb_can_reg_model_h[i].default_map` | `apb_master_sequencer` via `apb_environment_h[i].apb_reg2bus_adapter_h` | reg2bus (set in `apb_can_environment`) |
| `apb_master_monitor_proxy.apb_master_analysis_port` | `apb_predictor_h.bus_in` | bus2reg (connected in `apb_environment`) |
| `apb_predictor_h` (`apb_bus2reg_adapter_h`) | `apb_can_reg_model_h[i].default_map` | bus2reg (map set in `apb_can_environment`) |
| `apb_can_virtual_seqr_h` | `apb_master_seqr_h[i]`, `apb_can_reg_model_h[i]` | handles |
| `apb_master_monitor_proxy.apb_master_analysis_port` | `apb_can_scoreboard.apb_master_analysis_fifo` | analysis |
| `apb_master_monitor_proxy.apb_master_analysis_port` | `apb_can_subscriber.apb_analysis_imp` | analysis |
| `can_passive_monitor.can_analysis_port` | `apb_can_scoreboard.can_analysis_fifo` | analysis |
| `can_passive_monitor.can_analysis_port` | `apb_can_subscriber.can_analysis_imp` | analysis |
| `apb_master_driver_proxy` ↔ `apb_master_driver_bfm` | | virtual interface (config_db `apb_master_driver_bfm`) |
| `apb_master_monitor_proxy` ← `apb_master_monitor_bfm` | | virtual interface (config_db `apb_master_monitor_bfm`) |
| `can_passive_monitor` ← `can_interface` | | virtual interface (config_db `can_vif[i]`) |

## APB AVIP integration

Only the master-side files of the APB AVIP are used, in `src/dv/apb_avip/`:

| File | Purpose |
|------|---------|
| `globals/apb_global_pkg.sv` | widths, enums, structs |
| `hdl_top/apb_if/apb_if.sv` | APB pin interface |
| `hdl_top/master_agent_bfm/apb_master_{agent,driver,monitor}_bfm.sv` | APB_HDL_AVIP. `apb_master_agent_bfm` has a `NODE_ID` parameter (see Notes) |
| `hvl_top/master/*.sv` (11 files) | APB master agent, tx, sequencer, driver/monitor proxy, adapter, coverage, config |
| `hvl_top/env/apb_environment{,_pkg}.sv` | APB_ENVIRONMENT[]: master agent, predictor, reg2bus and bus2reg adapters (added for this bench) |

The register model is not part of the APB environment. It belongs to `apb_can_environment`
(APB_CAN_REG_MODEL[]), which connects it to the APB environment of its node. This keeps the APB side
free of CAN-specific code. There is one register model instance per node because each DUT has its own
APB bus and a UVM register map drives only one sequencer.

Not used (outside the architecture): slave agent/BFMs, `apb_env*`, `apb_scoreboard`, AVIP virtual sequencers,
`hdl_top.sv`, `hvl_top.sv`, AVIP tests/sequences and sim scripts.

The register model is `src/dv/ral/` (`can_reg_pkg`, generated by `gen_ral.py`). It is used unmodified
and compiled by the Makefile (`RAL_DIR := ./ral`).

## Notes / open points

- DUT `PADDR` is 12 bits; the AVIP `ADDRESS_WIDTH` is 32, so `paddr[11:0]` is connected.
- Multiple nodes: set with `make compile nodes=<n>` (`+define+NO_OF_NODES=<n>`, default 3). Each node gets its own
  `apb_if`, APB master agent BFM, `can_interface`, DUT, assertion module, register model, APB environment,
  CAN passive agent, scoreboard and subscriber. All `can_tx` lines are resolved by `can_bus` (wired-AND).
  `apb_master_agent_bfm #(.NODE_ID(i))` publishes its BFMs only to `*apb_master_agent_h[i]*`. For this reason the
  agent inside `apb_environment_h[i]` is named `apb_master_agent_h[i]`; the test sets the agent config with the
  same scope.
- `src/rtl/` is empty. Place `can_controller_top` and its submodules there; the Makefile picks up
  `*.sv`/`*.v` automatically. Until then, `make compile stub=1` uses `src/dv/stub/stub_can_controller_top.sv`,
  a register-only stand-in with the same ports (see README).
- Generated RAL issue: `tx_command` / `rx_command` are added to the map with `"WO"` rights but contain an
  `"RO"` `reserved` field. UVM reports this as a `RegModel` UVM_ERROR, which stops the build.
  `test/apb_can_ral_report_catcher.sv` demotes only that message to UVM_WARNING. The proper fix is in `gen_ral.py`;
  remove the catcher once the RAL is regenerated.
- Reset: `apb_can_top` starts with the resets de-asserted, asserts them at 15 ns and then releases them. The AVIP BFMs
  (`wait_for_preset_n`) wait for a falling edge followed by a rising edge of `preset_n`.

## Tests

| Test | Description |
|------|-------------|
| `apb_can_base_test` | Builds the environment and runs the empty virtual base sequence |
| `apb_can_reg_access_test` | RAL front-door access over APB: read VERSION, write and read back BRP |
