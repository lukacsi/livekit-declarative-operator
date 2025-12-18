"livekit-default-pool" as $POOL_NAME |
"default"              as $POOL_NS |
"livekit-server"       as $DEPLOY_NAME |

def to_ts:
  (. [0:19] + "Z" | fromdateiso8601) as $base
  | (. [20:26] | tonumber) as $micros
  | $base + ($micros / 1000000);

# Checks if the result array contains an Upserted event for a specific Kind/Name
def is_upserted($kind; $name):
  .payload.result[]? | select(
    .Type == "Upserted" and 
    .Object.kind == $kind and 
    (.Object.metadata.name == $name or $name == "*")
  ) | length > 0;

[inputs | select(.level == "INFO" or .level == "DEBUG")] | map(

  if .logger == "op-ctrl" and .message == "reconciling" and .payload.request == "/livekit-declarative-pool-to-views" then
    { phase: "T0_Start", time: .timestamp }

  elif .logger == "operator.pipeline"
       and .payload.controller == "pool-to-server-view" 
       and (
         .payload.result[]? | select(
           .Object.kind == "LiveKitServerView"
           and .Object.metadata.name == $POOL_NAME
           and .Object.metadata.namespace == $POOL_NS
           and .Type == "Upserted"
         )
       ) then
    { phase: "T1_Decomposition", time: .timestamp }

  elif .logger == "operator.pipeline"
       and .payload.controller == "server-view-to-deployment" 
       and (
         .payload.result[]? | select(
           .Object.kind == "Deployment"
           and .Object.metadata.name == "livekit-server" 
           and .Object.metadata.namespace == $POOL_NS
           and .Type == "Upserted"
         )
       ) then
    { phase: "T2_Materialization", time: .timestamp }

  elif .logger == "operator.pipeline" 
       and .payload.controller == "networking-status-aggregator" 
       and (
         .payload.result[]? | select(
           .Object.kind == "LiveKitNetworkingView"
           and .Object.metadata.name == $POOL_NAME 
           and .Object.metadata.namespace == $POOL_NS
           and (.Object.status.lbIP? | length > 0)
           and .Type == "Upserted"
         )
       ) then
    { phase: "T3_Discovery", time: .timestamp }

  elif .logger == "operator.pipeline" 
       and .payload.controller == "pool-status-from-networking-view" 
       and (
         .payload.result[]? | select(
           .Object.kind == "LiveKitPool"
           and .Object.metadata.name == $POOL_NAME 
           and .Object.metadata.namespace == $POOL_NS
           and (.Object.status.components.networking.lbIP? | length > 0)
           and .Type == "Upserted"
         )
       ) then
    { phase: "T4_Convergence", time: .timestamp }

  else empty end
)

| sort_by(.time) 
| unique_by(.phase)
| . as $events
| ($events[] | select(.phase == "T0_Start").time | to_ts) as $start_ts
| $events[] 
| . + { latency_ms: ((.time | to_ts) - $start_ts) * 1000 | floor }