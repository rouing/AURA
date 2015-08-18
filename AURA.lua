--@name Aura (Eve Online Project)
--@author Rouing
--@requiresv lib/setSubMaterialB.txt
--@model models/lt_c/holograms/console_hr.mdl
--@updater STEAM_0:1:29347854
--@class processor
--@autoupdate


--[[
		THIS IS NO WHERE NEAR FINISHED
		IF YOU HAVE FEEDBACK TELL ME
		]]--

-- I dont like botsay. I made my own bot say
function bsay(e)
	printColor(Color(255,0,0),"[AI] ",Color(100,100,255),"Aura",Color(255,255,255),": ",e)
	--chat.botSayAlliance("Aura",e)
	--chat.botSay("Arua",e)
end

if SERVER then -- Server Side
	-- Server Side Libraries
	local ply = _G.player

	-- Constants
	local SELF = ents.self()
	local OWNER = SELF:owner()
	local NAME = OWNER:name()
	local MAP = serverinfo.map()

	-- This is the name of your ship
	-- Define this using a constant value
	-- and placing it on the ship with
	-- A string (name of ship)
	local SHIPNAME

	-- This is your target
	local TARGET = nil
	-- This is your targets current damage status
	-- This is used to check if they turned off damage
	-- in the middle of the fight
	local TARGETStatus

	--[[
	These are the tables that hold data the processor will use
	Each one will only be populated it if the corrisponding
	Entity is found
	]]--
	local WARPPOSITIONS = {}
	local BEAMPOSITIONS = {}
	local SHIELDDIR     = {}
	local TORPEDOTYPES  = {}
	local TARGETTYPES   = {}

	-- Array of functions tables
	local AURA      = {}
	local LETTERS   = {}

	AURA.Status = "green" -- We always start at green status

	AURA.UTILITY    = {}

	AURA.COMMANDS           = {}
	AURA.COMMANDS.NOARG     = {} -- 0 Args
	AURA.COMMANDS.ONEARG    = {} -- 1 Arg
	AURA.COMMANDS.TWOARG    = {} -- 2 Args
	AURA.COMMANDS.THREEARG  = {} -- 3 Args

	-- Array of interfaceable ents
	AURA.INTERFACEABLE              = {}
	AURA.INTERFACEABLE.Lights       = {}
	AURA.INTERFACEABLE.Emitters     = {}
	AURA.INTERFACEABLE.Turrets      = {}
	AURA.INTERFACEABLE.Torpedos     = {}
	AURA.INTERFACEABLE.Launchers    = {}
	AURA.INTERFACEABLE.Forcefields  = {}
	AURA.INTERFACEABLE.PROPS        = {}
	AURA.INTERFACEABLE.GPSs         = {}
	AURA.INTERFACEABLE.Gyros        = {}
	AURA.INTERFACEABLE.Keepers      = {}
	AURA.INTERFACEABLE.Sound        = {}
	AURA.INTERFACEABLE.LPRecievers  = {}
	AURA.INTERFACEABLE.ShipCannons  = {}

	-- The target information
	AURA.Target = {}
	AURA.Target.Entity = null
	AURA.Target.Position = null

	-- Sound information
	AURA.SOUNDS = {}
	AURA.SOUNDS.RedAlert = "st/misc/tng_redalert.wav"
	AURA.SOUNDS.BlueAlert = "st/misc/bluealert.wav"
	AURA.SOUNDS.AbandonShip = "st/misc/abandon_ship.wav"
	AURA.SOUNDS.IntruderAlert = "st/misc/intruder_alert.wav"
	AURA.SOUNDS.YellowAlert = "st/shuttlecraft/yellowalert.wav"
	AURA.SOUNDS.Error = "st/shuttlecraft/computer_error.mp3"
	AURA.SOUNDS.Deny = "st/shuttlecraft/computer_deny.wav"

	-- These are the WARPDRIVE positions. (Per Map basis)
	function AURA.populateWarpPositions(map)
		if map == "sb_galaxies" then
			WARPPOSITIONS.shakur        = Vector(-7076.469,-9152.125,10060.281)
			WARPPOSITIONS.desert        = Vector(10813.469,-7631.781,-8541.219)
			WARPPOSITIONS.hiigara       = Vector(7144.75,5267.938,-4660.031)
			WARPPOSITIONS.lava          = Vector(-9891.5,-1500,-3800)
			WARPPOSITIONS.milk          = Vector(-10500,2500,700)
			WARPPOSITIONS.pegasus       = Vector(1703.844,-8593.844,9143.375)
			WARPPOSITIONS.universe      = Vector(4691,-8842,-11000)
			WARPPOSITIONS.hangar        = Vector(5227,-7711,8866)
			WARPPOSITIONS.earth         = Vector(-304,6238,9813)
			WARPPOSITIONS.moon          = Vector(-4938,13441,10444)
			WARPPOSITIONS.build         = Vector(13069,14057,-15282)
			WARPPOSITIONS.previous      = Vector(0,0,0)
		end
	end

	-- These are the transport pad positions
	function AURA.populateBeamPositions(map)
		if map == "sb_galaxies" then
			BEAMPOSITIONS.shakur        = Vector(-5825,-4099,6848)
			BEAMPOSITIONS.desert        = Vector(10767,-13104,-9280)
			BEAMPOSITIONS.hiigara       = Vector(7144.75,5267.938,-4660.031)
			BEAMPOSITIONS.lava          = Vector(-11164,608,-4640)
			BEAMPOSITIONS.hangar        = Vector(11583,-7472,9088)
			BEAMPOSITIONS.earth         = Vector(3048,8243,8080)
			BEAMPOSITIONS.moon          = Vector(-3483,13548,9952)
			BEAMPOSITIONS.build         = Vector(13069,14057,-15282)
		end
	end

	-- These are the indexes the shield uses to direct power
	function AURA.popluateShieldDirections()
		SHIELDDIR.balance       = -1
		SHIELDDIR.everywhere    = -1
		SHIELDDIR.normal        = 0
		SHIELDDIR.fore          = 1
		SHIELDDIR.front         = 1
		SHIELDDIR.aft           = 2
		SHIELDDIR.back          = 2
		SHIELDDIR.port          = 3
		SHIELDDIR.starboard     = 4
		SHIELDDIR.dorsal        = 5
		SHIELDDIR.top           = 5
		SHIELDDIR.ventral       = 6
		SHIELDDIR.bottom        = 6
	end

	-- These are the types of torpedos
	function AURA.populateTorpedoTypes()
		TORPEDOTYPES.photon                 = 1
		TORPEDOTYPES.quantum                = 2
		TORPEDOTYPES.plasma                 = 3
		TORPEDOTYPES.transphasic            = 4
		TORPEDOTYPES.chroniton              = 5
		TORPEDOTYPES.transphasic_chroniton  = 6
		TORPEDOTYPES.biomolecular           = 7
	end

	-- These are the target types you can pick from
	function AURA.populateTargetTypes()
		TARGETTYPES.glider       = "sg_vehicle_glider"
		TARGETTYPES.f302         = "sg_vehicle_f302"
		TARGETTYPES.dest         = "sg_vehicle_shuttle"
		TARGETTYPES.gateg        = "sg_vehicle_gate_glider"
		TARGETTYPES.teltac       = "sg_vehicle_teltac"
		TARGETTYPES.jumper       = "puddle_jumper"
		TARGETTYPES.core         = "ship_core"
		TARGETTYPES.node         = "stargazer_node"
		TARGETTYPES.gyro         = "gyropod_advanced"
		TARGETTYPES.sgshield     = "shield_generator"
		TARGETTYPES.shield       = "st_shield_emitter"
		TARGETTYPES.zpm          = "zpm_mk3"
		TARGETTYPES.ag3          = "ag_3"
		TARGETTYPES.drive        = "ship_drive"
		TARGETTYPES.sbepdrive    = "warpdrive"
		TARGETTYPES.turret       = "gmod_wire_turret"
		TARGETTYPES.ring         = "ring_base_ancient"
		TARGETTYPES.sat          = "stargate_asuran"
		TARGETTYPES.rotaty       = "sf-rotatybase"
		TARGETTYPES.prop         = "prop_physics"
		TARGETTYPES.npc          = "npc_*"
		TARGETTYPES.ragdoll      = "prop_ragdoll"
		TARGETTYPES.grenade      = "grenade_ar2"
		TARGETTYPES.stargate     = "stargate_*"
		TARGETTYPES.jamming      = "jamming_device"
		TARGETTYPES.ball         = "sent_ball"
		TARGETTYPES.shuttle      = "st_shuttle_type11"
		TARGETTYPES.e2           = "gmod_wire_expression2"
		TARGETTYPES.collector    = "stargazer_water_core_collector"
		TARGETTYPES.borg         = "box_*"
		TARGETTYPES.hoverball    = "gmod_hoverball"
	end

	-- Letters Table
	function AURA.populateLetters()
		LETTERS.A       = "models/sprops/misc/alphanum/alphanum_a.mdl"
		LETTERS.B       = "models/sprops/misc/alphanum/alphanum_b.mdl"
		LETTERS.C       = "models/sprops/misc/alphanum/alphanum_c.mdl"
		LETTERS.D       = "models/sprops/misc/alphanum/alphanum_d.mdl"
		LETTERS.E       = "models/sprops/misc/alphanum/alphanum_e.mdl"
		LETTERS.F       = "models/sprops/misc/alphanum/alphanum_f.mdl"
		LETTERS.G       = "models/sprops/misc/alphanum/alphanum_g.mdl"
		LETTERS.H       = "models/sprops/misc/alphanum/alphanum_h.mdl"
		LETTERS.I       = "models/sprops/misc/alphanum/alphanum_i.mdl"
		LETTERS.J       = "models/sprops/misc/alphanum/alphanum_j.mdl"
		LETTERS.K       = "models/sprops/misc/alphanum/alphanum_k.mdl"
		LETTERS.L       = "models/sprops/misc/alphanum/alphanum_l.mdl"
		LETTERS.M       = "models/sprops/misc/alphanum/alphanum_m.mdl"
		LETTERS.N       = "models/sprops/misc/alphanum/alphanum_n.mdl"
		LETTERS.O       = "models/sprops/misc/alphanum/alphanum_o.mdl"
		LETTERS.P       = "models/sprops/misc/alphanum/alphanum_p.mdl"
		LETTERS.Q       = "models/sprops/misc/alphanum/alphanum_q.mdl"
		LETTERS.R       = "models/sprops/misc/alphanum/alphanum_r.mdl"
		LETTERS.S       = "models/sprops/misc/alphanum/alphanum_s.mdl"
		LETTERS.T       = "models/sprops/misc/alphanum/alphanum_t.mdl"
		LETTERS.U       = "models/sprops/misc/alphanum/alphanum_u.mdl"
		LETTERS.V       = "models/sprops/misc/alphanum/alphanum_v.mdl"
		LETTERS.W       = "models/sprops/misc/alphanum/alphanum_w.mdl"
		LETTERS.X       = "models/sprops/misc/alphanum/alphanum_x.mdl"
		LETTERS.Y       = "models/sprops/misc/alphanum/alphanum_y.mdl"
		LETTERS.Z       = "models/sprops/misc/alphanum/alphanum_z.mdl"
		LETTERS.a       = "models/sprops/misc/alphanum/alphanum_l_a.mdl"
		LETTERS.b       = "models/sprops/misc/alphanum/alphanum_l_b.mdl"
		LETTERS.c       = "models/sprops/misc/alphanum/alphanum_l_c.mdl"
		LETTERS.d       = "models/sprops/misc/alphanum/alphanum_l_d.mdl"
		LETTERS.e       = "models/sprops/misc/alphanum/alphanum_l_e.mdl"
		LETTERS.f       = "models/sprops/misc/alphanum/alphanum_l_f.mdl"
		LETTERS.g       = "models/sprops/misc/alphanum/alphanum_l_g.mdl"
		LETTERS.h       = "models/sprops/misc/alphanum/alphanum_l_h.mdl"
		LETTERS.i       = "models/sprops/misc/alphanum/alphanum_l_i.mdl"
		LETTERS.j       = "models/sprops/misc/alphanum/alphanum_l_j.mdl"
		LETTERS.k       = "models/sprops/misc/alphanum/alphanum_l_k.mdl"
		LETTERS.l       = "models/sprops/misc/alphanum/alphanum_l_l.mdl"
		LETTERS.m       = "models/sprops/misc/alphanum/alphanum_l_m.mdl"
		LETTERS.n       = "models/sprops/misc/alphanum/alphanum_l_n.mdl"
		LETTERS.o       = "models/sprops/misc/alphanum/alphanum_l_o.mdl"
		LETTERS.p       = "models/sprops/misc/alphanum/alphanum_l_p.mdl"
		LETTERS.q       = "models/sprops/misc/alphanum/alphanum_l_q.mdl"
		LETTERS.r       = "models/sprops/misc/alphanum/alphanum_l_r.mdl"
		LETTERS.s       = "models/sprops/misc/alphanum/alphanum_l_s.mdl"
		LETTERS.t       = "models/sprops/misc/alphanum/alphanum_l_t.mdl"
		LETTERS.u       = "models/sprops/misc/alphanum/alphanum_l_u.mdl"
		LETTERS.v       = "models/sprops/misc/alphanum/alphanum_l_v.mdl"
		LETTERS.w       = "models/sprops/misc/alphanum/alphanum_l_w.mdl"
		LETTERS.x       = "models/sprops/misc/alphanum/alphanum_l_x.mdl"
		LETTERS.y       = "models/sprops/misc/alphanum/alphanum_l_y.mdl"
		LETTERS.z       = "models/sprops/misc/alphanum/alphanum_l_z.mdl"
		LETTERS["0"]    = "models/sprops/misc/alphanum/alphanum_0.mdl"
		LETTERS["1"]    = "models/sprops/misc/alphanum/alphanum_1.mdl"
		LETTERS["2"]    = "models/sprops/misc/alphanum/alphanum_2.mdl"
		LETTERS["3"]    = "models/sprops/misc/alphanum/alphanum_3.mdl"
		LETTERS["4"]    = "models/sprops/misc/alphanum/alphanum_4.mdl"
		LETTERS["5"]    = "models/sprops/misc/alphanum/alphanum_5.mdl"
		LETTERS["6"]    = "models/sprops/misc/alphanum/alphanum_6.mdl"
		LETTERS["7"]    = "models/sprops/misc/alphanum/alphanum_7.mdl"
		LETTERS["8"]    = "models/sprops/misc/alphanum/alphanum_8.mdl"
		LETTERS["9"]    = "models/sprops/misc/alphanum/alphanum_9.mdl"
		LETTERS["."]    = "models/sprops/misc/alphanum/alphanum_prd.mdl"
		LETTERS[" "]    = "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl"
		LETTERS["{"]    = "models/sprops/misc/alphanum/alphanum_lcbracket.mdl"
		LETTERS["}"]    = "models/sprops/misc/alphanum/alphanum_rcbracket.mdl"
		LETTERS["["]    = "models/sprops/misc/alphanum/alphanum_lbracket.mdl"
		LETTERS["]"]    = "models/sprops/misc/alphanum/alphanum_rbracket.mdl"
		LETTERS["("]    = "models/sprops/misc/alphanum/alphanum_lpar.mdl"
		LETTERS[")"]    = "models/sprops/misc/alphanum/alphanum_rpar.mdl"
		LETTERS["&"]    = "models/sprops/misc/alphanum/alphanum_and.mdl"
		LETTERS["#"]    = "models/sprops/misc/alphanum/alphanum_pdsign.mdl"
		LETTERS[":"]    = "models/sprops/misc/alphanum/alphanum_colon.mdl"
		LETTERS["\""]   = "models/sprops/misc/alphanum/alphanum_quote.mdl"
		LETTERS["\'"]   = "models/sprops/misc/alphanum/alphanum_quote.mdl"
		LETTERS["-"]    = "models/sprops/misc/alphanum/alphanum_min.mdl"
		LETTERS["+"]    = "models/sprops/misc/alphanum/alphanum_plu.mdl"
		LETTERS["="]    = "models/sprops/misc/alphanum/alphanum_equal.mdl"

	end

	-- UTILITY BLOCK
	--[[
	This is a set of functions that make my life easier or
	cannot be classified. They have a utility purpose and
	provide easy access to specific functions
	]]--

	--These are timer based utilites
	function AURA.UTILITY.findInShip()
		local LSCore = AURA.INTERFACEABLE.LSCore
		if LSCore then
			local Plys = find.allPlayers(function(E) return faction.getFaction(OWNER) ~= faction.getFaction(E) and E:getEnvironmentData().Entity == LSCore end)
			for I = 1, #Plys do
				AURA.COMMANDS.beam(Plys[I],"shakur")
				chat.tell(Plys[I],Color(255,0,0),"[AI] ",Color(100,100,255),"Aura",Color(255,255,255),": ","You have no authorization to be here!")
			end
		else
			bsay("A LS Core is required to find players in the ship!")
			timer.stop("FindInShip")
		end
	end
	timer.create("FindInShip",3,0,function() AURA.UTILITY.findInShip() end)

   function AURA.UTILITY.targetDamageStatusChanged()
		if TARGET and TARGET:isValid() then
			if TARGETStatus then
				TAR = TARGET
				if TAR ~= "player" then
					TAR = TAR:owner()
				end
				if TAR:hasDamageEnabled() ~= TARGETStatus then
					TARGETStatus = TAR:hasDamageEnabled()
					bsay(TAR:name() .. " has changed their damage status to: " .. tostring(TARGETStatus))
				end
			end
		else
			timer.stop("CheckDamageStatus")
		end
	end
	timer.create("CheckDamageStatus",3,0,function() AURA.UTILITY.targetDamageStatusChanged() end)

	function AURA.UTILITY.drawLetters() -- VERY COMPLICATED FOR WHAT IT DOES
		if SHIPNAME then -- check to see if SHIPNAME was defined
			local Name = SHIPNAME:explode("") -- Name of Ship (explode letter by letter)
			local temp = {} -- This is an array used for centering
			local length = 0 -- Length of the name after holos created
			for x = 1, #AURA.INTERFACEABLE.GPSs do -- For loop for each gps
				local GPS = AURA.INTERFACEABLE.GPSs[x] -- current gps
				local last = nil -- last letter (holo entity)
				local size = 0 -- size of the current holo(s)
				temp[x] = {} -- new array for a 3d array
				for i = 1, #Name do -- for each letter in the name
					local LETTER = LETTERS[Name[i]] -- current letter (see: LETTERS table)
					timer.simple(i*0.05, function() -- prevent high ops
						last = holograms.create(GPS:toWorld(Vector(0,size,0)), GPS:toWorld(Angle(0,-90,90)), LETTER, 3) -- create the holo
						if last:model() == LETTERS[" "] then -- if its a space
							last:setAlpha(0) -- set it to 0 alpha
						end -- end
						size = last:obbSize().z + size -- size (used in this for loop)
						length = last:obbSize().z + length -- length (used in centering)
						temp[x][i]=last -- assign the holo to the 3d array (used in centering)
					end) -- end (timer)
				end -- end (second for loop)
			end -- end (first for loop)
			timer.simple(#Name*0.1, function() -- for centering
				for i = 1, #temp do -- for each full holo
					for x = 1, #temp[i] do -- for each letter in the current full holo
						local cur = temp[i][x] -- current letter
						cur:setPos(cur:toWorld(Vector(((length/#temp)/2),0,0))) -- center it
						cur:setParent(SELF)
						-- Equation: length / # of gps (due to the fact that for some reason it adds more and more for each gps)
						-- then devide all that by half
					end -- end (second for loop)
				end -- end (first for loop)
			end) -- end (timer)
		end -- end nil check if statement
	end -- end (function)

	function AURA.UTILITY.positionKeepers(e)
		if #AURA.INTERFACEABLE.Keepers == 0 or #AURA.INTERFACEABLE.Gyros == 0 then
			return nil
		end
		if e == "Startup" then
			for i = 1, #AURA.INTERFACEABLE.Keepers do
				if AURA.INTERFACEABLE.Gyros[i] ~= nil then
					local Cur = AURA.INTERFACEABLE.Keepers[i]
					local CurG = AURA.INTERFACEABLE.Gyros[i]

					local Base = holograms.create(CurG:getPos(),CurG:getAngles(),"models/madman07/ship_rail/ship_stand.mdl",1)
					local Ball = holograms.create(CurG:toWorld(Vector(0,0,19)),CurG:getAngles(),"models/sprops/geometry/sphere_48.mdl")

					Base:setScale(0.5)
					Ball:setMaterial("Zup/ramps/ramp_metal")

					Base:setParent(CurG)
					Ball:setParent(CurG)

					Cur:setPos(CurG:toWorld(Vector(0,0,19)))
				end
			end
		else
			for i = 1, #AURA.INTERFACEABLE.Keepers do
				local Cur = AURA.INTERFACEABLE.Keepers[i]
				Cur:setAng((e - Cur:pos()):Angle() + Angle(90,0,0))
			end
		end
	end

	function AURA.UTILITY.positionCannons(e)
		if #AURA.INTERFACEABLE.ShipCannons == 0 or #AURA.INTERFACEABLE.LPRecievers == 0 then
			return nil
		end
		if e == "Startup" then
			for i = 1, #AURA.INTERFACEABLE.ShipCannons do
				if AURA.INTERFACEABLE.LPRecievers[i] then
					local Cur = AURA.INTERFACEABLE.ShipCannons[i]
					local CurR = AURA.INTERFACEABLE.LPRecievers[i]

					local Base = holograms.create(CurR:getPos(),CurR:getAngles(),"models/madman07/ship_rail/ship_stand.mdl",1)
					local Ball = holograms.create(CurR:toWorld(Vector(0,0,19)),Angle(0,0,0),"models/sprops/geometry/sphere_48.mdl")

					Base:setScale(0.5)
					Ball:setMaterial("Boba_Fett/textures/atlantiswall_blue")

					Ball:setParent(CurR)
					Base:setParent(CurR)

					AURA.INTERFACEABLE.ShipCannons[i] = Ball

					Cur:setPos(CurR:toWorld(Vector(0,0,-150)))
					Cur:setAng(CurR:toWorld(Angle(-90,0,0)))
					Cur:setAlpha(0)
				end
			end
		else
			for i = 1, #AURA.INTERFACEABLE.ShipCannons do
				local Cur = AURA.INTERFACEABLE.ShipCannons[i]
				Cur:setAng((e - Cur:pos()):Angle() + Angle(180,0,0))
			end
		end
	end

	-- Find all the entites that we can interface with
	function AURA.UTILITY.findInterfaceableEnts()
		bsay("Finding entites I can interface with..") -- Notify player
		local Constrained = SELF:getConstraints(
			function(E)
				class = E:class()
				if class == "prop_physics" then
					-- I am using this for submaterials/skins
					if string.find(v:model(),"modbridge/core") then
						if AURA.INTERFACEABLE.PROPS.Modbridge == nil then
							AURA.INTERFACEABLE.PROPS.Modbridge = {}
						end
						AURA.INTERFACEABLE.PROPS.Modbridge[#AURA.INTERFACEABLE.PROPS.Modbridge + 1 or 1] = v
					elseif v:model() == "models/lt_c/holo_keypad.mdl" then
						if AURA.INTERFACEABLE.PROPS.Keypads == nil then
							AURA.INTERFACEABLE.PROPS.Keypads = {}
						end
						AURA.INTERFACEABLE.PROPS.Keypads[#AURA.INTERFACEABLE.PROPS.Keypads + 1 or 1] = v
					end
				elseif class == "gmod_wire_gps" then
					if not LETTERS.A then -- Check to see if the table is populated by calling upon a letter
						AURA.populateLetters()
					end
					AURA.INTERFACEABLE.GPSs[#AURA.INTERFACEABLE.GPSs + 1] = v
				elseif class == "gmod_wire_value" then
					SHIPNAME = v:getWirelink()["1"]
				elseif class == "ship_core" and not AURA.INTERFACEABLE.Core then
					AURA.INTERFACEABLE.Core = v
				elseif class == "st_shield_emitter" and not AURA.INTERFACEABLE.Shield then
					AURA.INTERFACEABLE.Shield = v
					AURA.populateWarpPositions(MAP)
				elseif (class == "ship_drive" or class == "quantum_slipstream_drive") and not AURA.INTERFACEABLE.Drive then
					AURA.INTERFACEABLE.Drive = v
					AURA.popluateShieldDirections()
				elseif (class == "cloaking_generator" or class == "st_cloaking_device") and not AURA.INTERFACEABLE.Cloak then
					AURA.INTERFACEABLE.Cloak = v
				elseif class == "computer_core" and not AURA.INTERFACEABLE.ComputerCore then
					AURA.INTERFACEABLE.ComputerCore = v
				elseif class == "jamming_device" and not AURA.INTERFACEABLE.Jammer then
					AURA.INTERFACEABLE.Jammer = v
				elseif class == "stargazer_ls_core" and not AURA.INTERFACEABLE.LSCore then
					AURA.INTERFACEABLE.LSCore = v
					if SHIPNAME ~= nil then
						v:getWirelink()["Name"] = SHIPNAME
					end
				elseif class == "gmod_wire_teleporter" and not AURA.INTERFACEABLE.Adjuster then
					AURA.INTERFACEABLE.Adjuster = v
				elseif class == "transporter_pad" and not AURA.INTERFACEABLE.TransporterPad then
					AURA.INTERFACEABLE.TransporterPad = v
					AURA.populateBeamPositions(MAP)
				elseif class == "gmod_wire_light" then
					AURA.INTERFACEABLE.Lights[#AURA.INTERFACEABLE.Lights + 1] = v
				elseif class == "sensor_array" and not AURA.INTERFACEABLE.SensorArray then
					AURA.INTERFACEABLE.SensorArray = v
				elseif class == "phaser_emitter" or class == "beam_emitter"
					or class == "pulse_phaser_emitter" or class == "ship_laser" then
					AURA.INTERFACEABLE.Emitters[#AURA.INTERFACEABLE.Emitters + 1] = v
				elseif class == "ship_turret_base" then
					AURA.INTERFACEABLE.Turrets[#AURA.INTERFACEABLE.Turrets + 1] = v
				elseif class == "torpedo_launcher" then
					AURA.INTERFACEABLE.Torpedos[#AURA.INTERFACEABLE.Torpedos + 1] = v
				elseif class == "heavy_missile_pod" then
					AURA.INTERFACEABLE.Launchers[#AURA.INTERFACEABLE.Launchers + 1] = v
				elseif class == "st_forcefield_emitter" then
					AURA.INTERFACEABLE.Forcefields[#AURA.INTERFACEABLE.Forcefields + 1] = v
				elseif class == "transporter" and not AURA.INTERFACEABLE.AsgardTransporter then
					AURA.INTERFACEABLE.AsgardTransporter = v
					AURA.populateBeamPositions(MAP)
				elseif class == "tscm_tv" and not AURA.INTERFACEABLE.TV then
					AURA.INTERFACEABLE.TV = v
				elseif class == "gmod_wire_gyroscope" then
					AURA.INTERFACEABLE.Gyros[#AURA.INTERFACEABLE.Gyros + 1] = v
				elseif class == "keeper_emitter" then
					AURA.INTERFACEABLE.Keepers[#AURA.INTERFACEABLE.Keepers + 1] = v
				elseif class == "gmod_wire_soundemitter" then
					AURA.INTERFACEABLE.Sound[#AURA.INTERFACEABLE.Sound + 1] = v
				elseif class == "gmod_wire_las_receiver" then
					AURA.INTERFACEABLE.LPRecievers[#AURA.INTERFACEABLE.LPRecievers + 1] = v
				elseif class == "ship_cannon" then
					AURA.INTERFACEABLE.ShipCannons[#AURA.INTERFACEABLE.ShipCannons + 1] = v
				end
			end
		)
		bsay("Finished finding interfaceable entities.")
	end

	function AURA.UTILITY.PlaySound(sound,time,e)
		if e == nil then
			for i = 1, #AURA.INTERFACEABLE.Sound do
				local x = sounds.create(AURA.INTERFACEABLE.Sound[i],sound)
				x:play()
				timer.simple(time,function() x:stop() end)
			end
		end
		local y = sounds.create(SELF,sound)
		y:play()
		timer.simple(time,function() y:stop() end)
	end

	-- This is the commands.
	-- UTILITY COMMANDS
	function AURA.COMMANDS.FindModel()
		local AE = OWNER:aimEntity()
		if AE then
			bsay("The model of that is " .. AE:model() .. ".")
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	function AURA.COMMANDS.FindClass()
		local AE = OWNER:aimEntity()
		if AE then
			bsay("That would be an " .. AE:class())
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	function AURA.COMMANDS.FindOwner()
		local AE = OWNER:aimEntity()
		if AE then
			bsay(AE:owner():name() .. " is the owner of that.")
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	function AURA.COMMANDS.FindWeight()
		local AE = OWNER:aimEntity()
		if AE then
			bsay("The weight of that is: " .. AE:getMass() .. ".")
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	function AURA.COMMANDS.FindColor()
		local AE = OWNER:aimEntity()
		if AE then
			bsay("The color of that is: " .. AE:color() .. ".")
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	function AURA.COMMANDS.FindMaterial()
		local AE = OWNER:aimEntity()
		if AE then
			bsay("The material of that is: " .. AE:material() .. ".")
		else
			bsay("Are you looking at something?")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	-- Faction Commands
	function AURA.COMMANDS.FindOnlineFaction()
		local Friends = faction.getOnlineMembers()
		if #Friends > 0 then
			bsay("List of online fellow faction members:" .. Friends.toString() .. ".")
		else
			bsay("You currently have no faction members online.")
		end
	end

	function AURA.COMMANDS.FindOnlineAllies()
		local Allies = faction.getAlliedMembers()
		if #Allies > 0 then
			bsay("List of online allies:" .. table.toString(Allies,"Allies",true) .. ".")
		else
			bsay("You currently have no allies online.")
		end
	end

	-- LIFE SUPPORT
	function AURA.COMMANDS.LifeSupport(e)
		local LifeSupportEmitter = AURA.INTERFACEABLE.LSCore
		if LifeSupportEmitter then
			if e == "status" then
				local LSStatus = LifeSupportEmitter:getWirelink()["Active"]
				if LSStatus == 1 then
					bsay("Life support is currently active.")
				else
					bsay("Life support is currently inactive.")
				end
			else
				local LSStatus = LifeSupportEmitter:getWirelink()["Active"]
				if e then
					if LSStatus == 1 then
						bsay("Life Support is already enabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Enabling Life Support.")
						LifeSupportEmitter:getWirelink()["Activate"] = e
					end
				else
					if LSStatus == 0 then
						bsay("Life Support is already disabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Disabling Life Support.")
						LifeSupportEmitter:getWirelink()["Activate"] = e
					end
				end
			end
		else
			bsay("No Life Support Connected. Standing by.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
		end
	end

	-- CLOAK
	function  AURA.COMMANDS.Cloak(e)
		local CloakEmitter = AURA.INTERFACEABLE.Cloak
		if CloakEmitter then
			if e == "status" then
				local CStatus = CloakEmitter:getWirelink()["Active"]
				if CStatus == 1 then
					bsay("Cloak is currently active.")
				else
					bsay("Cloak is currently inactive.")
				end
			else
				local CStatus = CloakEmitter:getWirelink()["Active"]
				if e then
					if CStatus == 1 then
						bsay("Cloak is already enabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Enabling Cloak.")
						CloakEmitter:getWirelink()["Activate"] = e
					end
				else
					if CStatus == 0 then
						bsay("Cloak is already disabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Disabling cloak.")
						CloakEmitter:getWirelink()["Activate"] = e
					end
				end
			end
		else
			bsay("No Cloak Connected. Standing by.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	-- Jammer
	function AURA.COMMANDS.Jammer(e)
		local JammerEmitter = AURA.INTERFACEABLE.Jammer
		if JammerEmitter then
			if e == "status" then
				local JStatus = JammerEmitter:getWirelink()["Active"]
				if JStatus == 1 then
					bsay("Jammer is currently active.")
				else
					bsay("Jammer is currently inactive.")
				end
			else
				local JStatus = JammerEmitter:getWirelink()["Active"]
				if e then
					if JStatus == 1 then
						bsay("Jammer is already enabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Enabling jammer.")
						JammerEmitter:getWirelink()["Activate"] = e
					end
				else
					if JStatus == 0 then
						bsay("Jammer is already disabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Disabling jammer.")
						JammerEmitter:getWirelink()["Activate"] = e
					end
				end
			end
		else
			bsay("No Jammer Connected. Standing by.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	-- Forcefields
	function AURA.COMMANDS.Forcefields(e)
		local ForcefieldEmitters = AURA.INTERFACEABLE.Forcefields
		if #ForcefieldEmitters > 0 then
			if e == "status" then
				local FStatus = ForcefieldEmitters[1]:getWirelink()["Active"]
				if FStatus == 1 then
					bsay("Forcefields are currently active.")
				else
					bsay("Forcefields are currently inactive.")
				end
			else
				local FStatus = ForcefieldEmitters[1]:getWirelink()["Active"]
				if e then
					if FStatus == 1 then
						bsay("Forcefields is already enabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Enabling forcefields.")
						for i = 1, #ForcefieldEmitters do
							local FF = ForcefieldEmitters[ i ]
							if not FF then break end
							FF:getWirelink()["Activate"] = e
						end
					end
				else
					if FStatus == 0 then
						bsay("Forcefields is already disabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Disabling forcefields.")
						for i = 1, #ForcefieldEmitters do
							local FF = ForcefieldEmitters[ i ]
							if not FF then break end
							FF:getWirelink()["Activate"] = e
						end
					end
				end
			end
		else
			bsay("No Forcefields Connected. Standing by.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	-- Shield
	function AURA.COMMANDS.Shield(e)
		local ShieldEmitter = AURA.INTERFACEABLE.Shield
		if ShieldEmitter then
			if SHIELDDIR[e] then
				bsay("Divirting shield power to " .. e .. ".")
				ShieldEmitter:getWirelink()["Divert Power"] = SHIELDDIR[e]
			elseif e == "status" then
				local SStatus = ShieldEmitter:getWirelink()["Active"]
				if SStatus == 1 then
					bsay("Shield are currently active.")
				else
					bsay("Shield are currently inactive.")
				end
			else
				local SStatus = ShieldEmitter:getWirelink()["Active"]
				if e == 1 then
					if SStatus == 1 then
						bsay("Shield is already enabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Enabling Shield.")
						ShieldEmitter:getWirelink()["Activate"] = e
					end
				else
					if SStatus == 0 then
						bsay("Shield is already disabled.")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					else
						bsay("Disabling Shield.")
						ShieldEmitter:getWirelink()["Activate"] = e
					end
				end
			end
		else
			bsay("No Shield Connected. Standing by.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
		end
	end

	-- STATUS
	function AURA.COMMANDS.Status(e)
		local ShieldEmitter = AURA.INTERFACEABLE.Shield
		local ForcefieldEmitters = AURA.INTERFACEABLE.Forcefields
		local Core = AURA.INTERFACEABLE.Core

		if e == "green" then
			if AURA.Status ~= "green" then
				AURA.Status = "green"
				bsay(SHIPNAME .. " is now at green status.")

				AURA.INTERFACEABLE.Shield:getWirelink()["Activate"] = 0

				if Core then
					Core:getWirelink()["Enable Plating"] = 0
				end

				for i = 1, #AURA.INTERFACEABLE.Forcefields do
					local FF = AURA.INTERFACEABLE.Forcefields[ i ]
					if not FF then break end
					FF:getWirelink()["Activate"] = 0
				end

				for i = 1, #AURA.INTERFACEABLE.PROPS.Modbridge do
					local Prop = AURA.INTERFACEABLE.PROPS.Modbridge[i]
					if not Prop then break end
					setSubMaterialB(Prop,"cmats/light","cmats/light")
				end

				if #AURA.INTERFACEABLE.Lights > 0 then
					for i = 1, #AURA.INTERFACEABLE.Lights do
						local Light = AURA.INTERFACEABLE.Lights[i]
						if not Light then break end
						Light:getWirelink()["RGB"] = Vector(0,0,0)
					end
				end
			else
				bsay("The " .. SHIPNAME .. " is already at condition green.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
			end
		elseif e == "yellow" then
			if AURA.Status ~= "yellow" then
				AURA.Status = "yellow"
				bsay(SHIPNAME .. " is now at yellow alert! Defences enabled.")

				AURA.INTERFACEABLE.Shield:getWirelink()["Activate"] = 1

				if Core then
					Core:getWirelink()["Enable Plating"] = 1
				end

				for i = 1, #AURA.INTERFACEABLE.Forcefields do
					local FF = AURA.INTERFACEABLE.Forcefields[ i ]
					if not FF then break end
					FF:getWirelink()["Activate"] = 1
				end

				for i = 1, #AURA.INTERFACEABLE.PROPS.Modbridge do
					local Prop = AURA.INTERFACEABLE.PROPS.Modbridge[i]
					if not Prop then break end
					setSubMaterialB(Prop,"cmats/light","glow/yellow_light")
				end

				if #AURA.INTERFACEABLE.Lights > 0 then
					for i = 1, #AURA.INTERFACEABLE.Lights do
						local Light = AURA.INTERFACEABLE.Lights[i]
						if not Light then break end
						Light:getWirelink()["RGB"] = Vector(255,255,0)
					end
				end

				AURA.UTILITY.PlaySound(AURA.SOUNDS.YellowAlert,3)
			else
				bsay("The " .. SHIPNAME .. " is already at yellow alert.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
			end
		elseif e == "red" then
			if AURA.Status ~= "red" then
				AURA.Status = "red"
				bsay(SHIPNAME .. " is now at red alert!")

				AURA.INTERFACEABLE.Shield:getWirelink()["Activate"] = 1

				for i = 1, #AURA.INTERFACEABLE.Forcefields do
					local FF = AURA.INTERFACEABLE.Forcefields[ i ]
					if not FF then break end
					FF:getWirelink()["Activate"] = 1
				end

				if Core ~= nil then
					Core:getWirelink()["Enable Plating"] = 1
				end

				for i = 1, #AURA.INTERFACEABLE.PROPS.Modbridge do
					local Prop = AURA.INTERFACEABLE.PROPS.Modbridge[i]
					if not Prop then break end
					setSubMaterialB(Prop,"cmats/light","cmats/flash_red")
				end

				if #AURA.INTERFACEABLE.Lights > 0 then
					for i = 1, #AURA.INTERFACEABLE.Lights do
						local Light = AURA.INTERFACEABLE.Lights[i]
						if not Light then break end
						Light:getWirelink()["RGB"] = Vector(255,0,0)
					end
				end

				AURA.UTILITY.PlaySound(AURA.SOUNDS.RedAlert,15)
			else
				bsay("The " .. SHIPNAME .. " is already at red alert.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
			end
		elseif (e == "blue") then
			if (AURA.Status ~= "blue") then
				AURA.Status = "blue"
				bsay(SHIPNAME .. " is now at blue alert!")

				AURA.INTERFACEABLE.Shield:getWirelink()["Activate"] = 0

				if Core ~= nil then
					Core:getWirelink()["Enable Plating"] = 1
				end

				for i = 1, #AURA.INTERFACEABLE.Forcefields do
					local FF = AURA.INTERFACEABLE.Forcefields[ i ]
					if not FF then break end
					FF:getWirelink()["Activate"] = 1
				end

				for i = 1, #AURA.INTERFACEABLE.PROPS.Modbridge do
					local Prop = AURA.INTERFACEABLE.PROPS.Modbridge[i]
					if not Prop then break end
					setSubMaterialB(Prop,"cmats/light","glow/flash_blue")
				end

				if #AURA.INTERFACEABLE.Lights > 0 then
					for y = 1, #AURA.INTERFACEABLE.Lights do
						local Light = AURA.INTERFACEABLE.Lights[y]
						if not Light then break end
						Light:getWirelink()["RGB"] = Vector(0,0,255)
					end
				end

				AURA.UTILITY.PlaySound(AURA.SOUNDS.BlueAlert,15)
			else
				bsay("The " .. SHIPNAME .. " is already at blue alert.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
			end
		end
	end

	function AURA.COMMANDS.Beam(e,f)
		local Asgard = AURA.INTERFACEABLE.AsgardTransporter
		local Transporter = AURA.INTERFACEABLE.TransporterPad
		if Asgard or Transporter then
			local Destination = Vector(0,0,0)
			local Origin = Vector(0,0,0)
			local OEnt = nil
			local BeamAll = 0
			if BEAMPOSITIONS[f] ~= nil then
				Destination = BEAMPOSITIONS[f]
			elseif find.playerByName(f) ~= nil then
				Destination = find.playerByName(f):toWorld(Vector(-100,0,0))
			elseif f == "ship" then
				Destination = Transporter:getPos()+Vector(0,0,10)
			elseif f == "here" then
				Destination = OWNER:aimPos()
			else
				bsay("Invalid destination.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
			end

			if e == "me" then
				OEnt = OWNER
				Origin = OEnt:pos()
				BeamAll = 0
			elseif e == "that" then
				OEnt = OWNER:aimEntity()
				Origin = OEnt:pos()
				BeamAll = 1
			elseif find.playerByName(e) ~= nil then
				OEnt = find.playerByName(e)
				Origin = OEnt:pos()
				BeamAll = 0
			else
				bsay("Invalid beam origin.")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
			end

			if Origin ~= Vector(0,0,0) and Destination ~= Vector(0,0,0) and OEnt:isValid() then
				if Asgard then
					stargate.teleport(Asgard,Origin,Destination,BeamAll)
				elseif Transporter then
					Transporter:getWirelink()["Target1"] = OEnt
					Transporter:getWirelink()["TargetLocation"] = Destination
					timer.simple(2,function() Transporter:getWirelink()["Beam to vector"] = 1 Transporter:getWirelink()["Energise pad"] = 1 end)
					timer.simple(4,function() Transporter:getWirelink()["Beam to vector"] = 0 Transporter:getWirelink()["Energise pad"] = 0 end)
				else
					OEnt:setPos(Destination)
				end
				bsay("Energising...")
			end
		else
			bsay("No 'Transporter' connected.")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
		end
	end

	function AURA.COMMANDS.Warp(e)
		local DRIVE = AURA.INTERFACEABLE.Drive
		if DRIVE then
			if WARPPOSITIONS[e] then
				if e == "previous" and WARPPOSITIONS[e] == Vector(0,0,0) then
					return nil
				end
				WARPPOSITIONS.previous = DRIVE:getPos()
				DRIVE:getWirelink()["Destination"] = WARPPOSITIONS[e]
				DRIVE:getWirelink()["Activate"] = 1
				timer.simple(1,function() DRIVE:getWirelink()["Activate"] = 1 end)
			else
				bsay("Invalid warp position!")
			end
		else
			bsay("No Drive connected")
		end
	end

	function AURA.COMMANDS.Target(e,f,g)
		if f == "" or f == nil then
			if e == "this" or e == "that" then
				TARGET = OWNER:aimEntity()
				if TARGET then
					local Owner = TARGET:owner()
					if Owner and Owner:isValid() then
						TARGETStatus = Owner:hasDamageEnabled()
						bsay("Targeting: " .. TARGET:class() .. ". Owned by: " .. Owner)
						bsay("Owner has damage enabled?: " .. tostring(TARGETStatus))
						timer.start("CheckDamageStatus")
					end
				else
					if not g then
						bsay("You are not looking at anything!")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
					end
				end
			else
				TARGET = find.playerByName(e)
				if TARGET == nil then
					if not g then
						bsay("Invalid Player!")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
					end
				else
					TARGETStatus = TARGET:hasDamageEnabled()
					bsay("Targeting: " .. TARGET:name())
					bsay("Damage enabled?: " .. tostring(TARGETStatus))
					timer.start("CheckDamageStatus")
				end
			end
		elseif f == "direct" then
			bsay("Targeting: " .. e)
			TARGET = e
		elseif TARGETTYPES[f] then
			local Owner = find.playerByName(e)
			if Owner then
				find.byClass(TARGETTYPES[f], function(e)
					if e:owner() == Owner then
						TARGET = e
						return
					end
				end)
				if TARGET ~= nil then
					TARGETStatus = Owner:hasDamageEnabled()
					if Owner and Owner:isValid() then
						bsay("Targeting " .. TARGET:class() .. " owned by: " .. Owner:name())
						bsay("Owner has damage enabled?: " .. tostring(TARGETStatus))
						timer.start("CheckDamageStatus")
					end
				else
					if not g then
						bsay("Target not found!")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					end
				end
			else
				if not g then
					bsay("Invalid Player!")
					AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
				end
			end
		else
			if not g then
				bsay("Invalid target type!")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
			end
		end

		if AURA.INTERFACEABLE.SensorArray and TARGET then
			AURA.INTERFACEABLE.SensorArray:getWirelink()["Target"] = TARGET
		end

		if AURA.INTERFACEABLE.ComputerCore and TARGET and TARGET:isValid() then
			AURA.INTERFACEABLE.ComputerCore:getWirelink()["Target"] = TARGET
		end
	end

	function AURA.COMMANDS.Repair(e)
		local Owner = find.playerByName(e)
		if AURA.INTERFACEABLE.Core then
			if Owner and Owner ~= OWNER then
				local REPTARGET
				find.byClass("ship_core", function(e)
					if e:owner() == Owner then
						REPTARGET = e
						return
					end
				end)
				if REPTARGET then
					if AURA.INTERFACEABLE.Core:pos():DistToSqr(REPTARGET:pos()) < 67108864 then
						AURA.INTERFACEABLE.Core:setRepairTarget(REPTARGET)
						AURA.INTERFACEABLE.Core:fireRepairBeam(1)
						bsay("Repairing " .. Owner:name() .. "'s ship!")
					else
						bsay("The repair target is too far away!")
						AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
					end
				else
					bsay("Repair target not found!")
					AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
				end
			elseif Owner == OWNER then
				bsay("You can't repair yourself!")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
			else
				bsay("Invalid Player!")
				AURA.UTILITY.PlaySound(AURA.SOUNDS.Error,4,1)
			end
		else
			bsay("No Ship Core connected!")
			AURA.UTILITY.PlaySound(AURA.SOUNDS.Deny,4,1)
		end
	end

	function AURA.COMMANDS.AdjustShip()
		local TELE = AURA.INTERFACEABLE.Adjuster
		if TELE then
			TELE:getWirelink()["TargetAngle"] = OWNER:eyeAngles()
			TELE:getWirelink()["TargetPos"] = OWNER:getPos()
			TELE:getWirelink()["Jump"] = 1
			timer.simple(1,function() TELE:getWirelink()["Jump"] = 0 end)
		else
			bsay("No Wire Teleporter connected.")
		end
	end

	-- This is the list of commands
	-- No arguments
	AURA.COMMANDS.NOARG["what model is this"]   = function() AURA.COMMANDS.FindModel() end
	AURA.COMMANDS.NOARG["what model is that"]   = function() AURA.COMMANDS.FindModel() end
	AURA.COMMANDS.NOARG["identify model"]       = function() AURA.COMMANDS.FindModel() end
	AURA.COMMANDS.NOARG["what is this model"]   = function() AURA.COMMANDS.FindModel() end

	AURA.COMMANDS.NOARG["who owns this"]    = function() AURA.COMMANDS.FindOwner() end
	AURA.COMMANDS.NOARG["who owns that"]    = function() AURA.COMMANDS.FindOwner() end
	AURA.COMMANDS.NOARG["identify owner"]   = function() AURA.COMMANDS.FindOwner() end

	AURA.COMMANDS.NOARG["what is that"]     = function() AURA.COMMANDS.FindClass() end
	AURA.COMMANDS.NOARG["what is this"]     = function() AURA.COMMANDS.FindClass() end
	AURA.COMMANDS.NOARG["identify this"]    = function() AURA.COMMANDS.FindClass() end
	AURA.COMMANDS.NOARG["identify that"]    = function() AURA.COMMANDS.FindClass() end

	AURA.COMMANDS.NOARG["how much does that weigh"] = function() AURA.COMMANDS.FindWeight() end
	AURA.COMMANDS.NOARG["how much does this weigh"] = function() AURA.COMMANDS.FindWeight() end
	AURA.COMMANDS.NOARG["identify weight"]          = function() AURA.COMMANDS.FindWeight() end
	AURA.COMMANDS.NOARG["identify mass"]            = function() AURA.COMMANDS.FindWeight() end

	AURA.COMMANDS.NOARG["what is the color of that"]    = function() AURA.COMMANDS.FindColor() end
	AURA.COMMANDS.NOARG["what is the color of this"]    = function() AURA.COMMANDS.FindColor() end
	AURA.COMMANDS.NOARG["identify color"]               = function() AURA.COMMANDS.FindColor() end

	AURA.COMMANDS.NOARG["what is the material of that"] = function() AURA.COMMANDS.FindMaterial() end
	AURA.COMMANDS.NOARG["what is the material of this"] = function() AURA.COMMANDS.FindMaterial() end
	AURA.COMMANDS.NOARG["identify material"]            = function() AURA.COMMANDS.FindMaterial() end

	AURA.COMMANDS.NOARG["list online faction members"]  = function() AURA.COMMANDS.FindOnlineFaction() end
	AURA.COMMANDS.NOARG["list online allies"]           = function() AURA.COMMANDS.FindOnlineAllies() end

	AURA.COMMANDS.NOARG["enable life support"]  = function() AURA.COMMANDS.LifeSupport(1) end
	AURA.COMMANDS.NOARG["enable ls"]            = function() AURA.COMMANDS.LifeSupport(1) end
	AURA.COMMANDS.NOARG["ls on"]                = function() AURA.COMMANDS.LifeSupport(1) end

	AURA.COMMANDS.NOARG["disable life support"] = function() AURA.COMMANDS.LifeSupport(0) end
	AURA.COMMANDS.NOARG["disable ls"]           = function() AURA.COMMANDS.LifeSupport(0) end
	AURA.COMMANDS.NOARG["ls off"]               = function() AURA.COMMANDS.LifeSupport(0) end

	AURA.COMMANDS.NOARG["life support status"]  = function() AURA.COMMANDS.LifeSupport("status") end
	AURA.COMMANDS.NOARG["ls status"]            = function() AURA.COMMANDS.LifeSupport("status") end

	AURA.COMMANDS.NOARG["enable cloak"]     = function() AURA.COMMANDS.Cloak(1) end
	AURA.COMMANDS.NOARG["disable cloak"]    = function() AURA.COMMANDS.Cloak(0) end
	AURA.COMMANDS.NOARG["cloak status"]     = function() AURA.COMMANDS.Cloak("status") end

	AURA.COMMANDS.NOARG["enable jammer"]    = function() AURA.COMMANDS.Jammer(1) end
	AURA.COMMANDS.NOARG["disable jammer"]   = function() AURA.COMMANDS.Jammer(0) end
	AURA.COMMANDS.NOARG["jammer status"]    = function() AURA.COMMANDS.Jammer("status") end

	AURA.COMMANDS.NOARG["enable forcefields"]   = function() AURA.COMMANDS.Forcefields(1) end
	AURA.COMMANDS.NOARG["disable forcefields"]  = function() AURA.COMMANDS.Forcefields(0) end
	AURA.COMMANDS.NOARG["forcefields status"]   = function() AURA.COMMANDS.Forcefields("status") end

	AURA.COMMANDS.NOARG["enable shields"]   = function() AURA.COMMANDS.Shield(1) end
	AURA.COMMANDS.NOARG["enable shield"]    = function() AURA.COMMANDS.Shield(1) end
	AURA.COMMANDS.NOARG["disable shields"]  = function() AURA.COMMANDS.Shield(0) end
	AURA.COMMANDS.NOARG["disable shield"]   = function() AURA.COMMANDS.Shield(0) end
	AURA.COMMANDS.NOARG["shield status"]    = function() AURA.COMMANDS.Shield("status") end
	AURA.COMMANDS.NOARG["shields status"]   = function() AURA.COMMANDS.Shield("status") end

	AURA.COMMANDS.NOARG["green status"] = function() AURA.COMMANDS.Status("green") end
	AURA.COMMANDS.NOARG["yellow alert"] = function() AURA.COMMANDS.Status("yellow") end
	AURA.COMMANDS.NOARG["red alert"]    = function() AURA.COMMANDS.Status("red") end
	AURA.COMMANDS.NOARG["blue alert"]   = function() AURA.COMMANDS.Status("blue") end

	AURA.COMMANDS.NOARG["stop repair"]  = function() AURA.INTERFACEABLE.Core:fireRepairBeam(0) end

	AURA.COMMANDS.NOARG["adjust ship"]   = function() AURA.COMMANDS.AdjustShip() end

	-- One Argument
	AURA.COMMANDS.ONEARG["divert shield power"] = function(e) AURA.COMMANDS.Shield(e) end
	AURA.COMMANDS.ONEARG["divert shields"]      = function(e) AURA.COMMANDS.Shield(e) end
	AURA.COMMANDS.ONEARG["shield power"]        = function(e) AURA.COMMANDS.Shield(e) end

	AURA.COMMANDS.ONEARG["warp"] = function(e) AURA.COMMANDS.Warp(e) end
	AURA.COMMANDS.ONEARG["jump"] = function(e) AURA.COMMANDS.Warp(e) end

	AURA.COMMANDS.ONEARG["target"] = function(e) AURA.COMMANDS.Target(e,"") end

	AURA.COMMANDS.ONEARG["repair"] = function(e) AURA.COMMANDS.Repair(e) end

	-- Two Arguments
	AURA.COMMANDS.TWOARG["beam"]        = function(e,f) AURA.COMMANDS.Beam(e,f) end
	AURA.COMMANDS.TWOARG["teleport"]    = function(e,f) AURA.COMMANDS.Beam(e,f) end
	AURA.COMMANDS.TWOARG["send"]        = function(e,f) AURA.COMMANDS.Beam(e,f) end

	AURA.COMMANDS.TWOARG["target"] = function(e,f) AURA.COMMANDS.Target(e,f) end

	function chatToCommand(Message, Player)
		local Said = string.gsub(string.gsub(string.gsub(Message:lower(),"'s",""), " to",""),"[^%w ]","")
		local Args = Said:explode(" ")
		if Player == OWNER then
			--1 Arg
			local OneArgTest = ""
			for i = 1, #Args do
				if not (i==#Args) then
					OneArgTest = OneArgTest .. Args[i] .. " "
				end
			end
			OneArgTest = string.sub(OneArgTest,0,string.len(OneArgTest)-1)-- Remove that " " at the end. Looks Ugly!

			--2 Args
			local TwoArgTest = ""
			for i = 1, #Args do
				if not (i>=#Args-1) then
					TwoArgTest = TwoArgTest .. Args[i] .. " "
				end
			end
			TwoArgTest = string.sub(TwoArgTest,0,string.len(TwoArgTest)-1)-- Remove that " " at the end. Looks Ugly!

			if not (AURA.COMMANDS.NOARG[Said] == nil) then
				AURA.COMMANDS.NOARG[Said]()
				return true
			elseif not (AURA.COMMANDS.ONEARG[OneArgTest] == nil) then
				AURA.COMMANDS.ONEARG[OneArgTest](Args[#Args])
				return true
			elseif not(AURA.COMMANDS.TWOARG[TwoArgTest] == nil) then
				AURA.COMMANDS.TWOARG[TwoArgTest](Args[#Args-1],Args[#Args])
				return true
			end
		end
	end

	function initalize()
		bsay("Aura bootup sequence starting.")
		timer.simple(1,function() AURA.UTILITY.findInterfaceableEnts() end)
		timer.simple(3,function() AURA.UTILITY.drawLetters() end)
		timer.simple(5,function() AURA.populateTargetTypes() end)
		timer.simple(7,function() AURA.UTILITY.positionKeepers("Startup") end)
		timer.simple(8,function() AURA.UTILITY.positionCannons("Startup") end)
		timer.simple(9,function() AURA.UTILITY.startupMessage() end)
	end

	-- now listen to chat
	initalize()
	chat.listen(chatToCommand,OWNER)

	--[[
		This is the Hooks partition of this AI
	]]--

	hook.add("EntityTakeDamage","TakingDamage",
		function(ent,inflictor,attacker,amount)
			if ent:owner() == OWNER then
				if AURA.Status ~= "red" then
					AURA.COMMANDS.Status("red")
					if attacker and attacker:isValid() then
						if attacker:name() ~= nil then
							bsay("Taking damage from: " .. attacker:name())
							AURA.COMMANDS.Target(attacker:name(), "core", 1)
							if TARGET:isValid() == false then
								AURA.COMMANDS.Target(attacker, "direct", 1)
							end
						else
							bsay("Taking damage from: " .. attacker:class())
						end
					end
					if TARGET == nil and TARGET:isValid() == false then
						AURA.COMMANDS.Target(attacker:name())
					end
					if inflictor then
						bsay("Attacked with: " .. inflictor:class())
					end
				end
			end
		end
	)

end
