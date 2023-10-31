dofile( "$CONTENT_61d4b3e3-c5f7-454c-87fb-7a0fff5d91d0/Scripts/partUUIDs.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )

-- Container
print( "[FANT MOD] Vanilla Conatiner Amount:", #ContainerUuids )
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_chest
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_large_container
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_teleport_pipe_in
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_teleport_pipe_out
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_pumpjack_out
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_trashcan
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_recycler
ContainerUuids[#ContainerUuids + 1] = obj_interactive_fant_thin_chest
print( "[FANT MOD] Modded Conatiner Amount:", #ContainerUuids )

-- Pipes
print( "[FANT MOD] Vanilla Pipe Amount:", #PipeUuids )
PipeUuids[#PipeUuids + 1] = obj_interactive_mcp
PipeUuids[#PipeUuids + 1] = obj_interactive_mcp2
PipeUuids[#PipeUuids + 1] = obj_interactive_mcp3
--PipeUuids[#PipeUuids + 1] = obj_interactive_fant_pumpPipe
print( "[FANT MOD] Modded Pipe Amount:", #PipeUuids )