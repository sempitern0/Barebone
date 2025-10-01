## In this singleton will live all global events that you need to share across your game

extends Node



#region Interactables
@warning_ignore("unused_signal")
signal interactable_3d_focused(interactable: Interactable3D)
@warning_ignore("unused_signal")
signal interactable_3d_unfocused(interactable: Interactable3D)
@warning_ignore("unused_signal")
signal interactable_3d_interacted(interactable: Interactable3D)
@warning_ignore("unused_signal")
signal interactable_3d_canceled_interaction(interactable: Interactable3D)
@warning_ignore("unused_signal")
signal interactable_3d_interaction_limit_reached(interactable: Interactable3D)

#endregion
