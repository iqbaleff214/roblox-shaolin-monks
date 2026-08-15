-- GDD §13.2. Seed translation content, namespaced per §13.2's convention
-- (ui.*, hud.*, fx.*, container.*, mobile.*, enemy.*). A real, working, but
-- deliberately small seed — full 8-language coverage of every UI string is
-- localization-content work (a Studio/website content pipeline), not
-- something this engineering task invents. "en" is always fully populated
-- (required, since Translator/T-150 falls back to it); "id" here is
-- intentionally partial, so the fallback path has something real to
-- demonstrate rather than only ever hitting the trivial en-to-en case.

return {
	en = {
		["ui.button.back"] = "Back",
		["ui.button.next"] = "Next",
		["ui.screen.lobby"] = "Lobby",
		["ui.screen.chapterselect"] = "Chapter Select",
		["ui.screen.partysetup"] = "Party Setup",
		["ui.screen.loadoutcheck"] = "Loadout Check",
		["ui.screen.ready"] = "Ready",
		["ui.screen.load"] = "Load",
		["hud.label.combo"] = "Combo",
		["fx.message.finishingmove"] = "FINISHING MOVE",
		["fx.message.flawless"] = "FLAWLESS!",
		["fx.message.containerbroken"] = "broken!",
		["container.name.woodencrate"] = "Wooden Crate",
		["container.name.clayurn"] = "Clay Urn",
		["container.name.supplybarrel"] = "Supply Barrel",
		["container.name.jadechest"] = "Jade Chest",
		["mobile.button.attack"] = "Attack",
		["mobile.button.ultimate"] = "Ult",
		["mobile.button.grab"] = "Grab",
		["mobile.button.dodge"] = "Dodge",
		["mobile.button.shield"] = "Shield",
		["enemy.name.wraithbruiser"] = "Wraith Bruiser",
	},

	id = {
		["ui.button.back"] = "Kembali",
		["ui.button.next"] = "Lanjut",
	},
}
