
ARMOR_INIT_DELAY = 1
ARMOR_INIT_TIMES = 1
ARMOR_BONES_DELAY = 1
ARMOR_UPDATE_TIME = 1
ARMOR_DROP = false
ARMOR_DESTROY = false
ARMOR_LEVEL_MULTIPLIER = 1
ARMOR_HEAL_MULTIPLIER = 1
ARMOR_MATERIALS = {
	wood = "default:stick",
	cactus = "default:cactus",
	steel = "default:steel_ingot",
	bronze = "default:bronze_ingot",
	diamond = "default:diamond",
	gold = "default:gold_ingot",
	mithril = "moreores:mithril_ingot",
	crystal = "ethereal:crystal_ingot",
}
ARMOR_FIRE_PROTECT = true
ARMOR_FIRE_NODES = {
	{"default:lava_source",     5, 4},
	{"default:lava_flowing",    5, 4},
	{"fire:basic_flame",        3, 4},
	{"ethereal:crystal_spike",  2, 1},
	{"bakedclay:safe_fire",     2, 1},
	{"technic:corium_source",   2, 2},
	{"technic:corium_flowing",  2, 2},
	{"tutorial:xp_block",		2, 5},
}

local skin_mod = nil
local inv_mod = nil

local modpath = minetest.get_modpath(ARMOR_MOD_NAME)
local worldpath = minetest.get_worldpath()
local input = io.open(modpath.."/armor.conf", "r")
if input then
	dofile(modpath.."/armor.conf")
	input:close()
	input = nil
end
input = io.open(worldpath.."/armor.conf", "r")
if input then
	dofile(worldpath.."/armor.conf")
	input:close()
	input = nil
end
if not minetest.get_modpath("moreores") then
	ARMOR_MATERIALS.mithril = nil
end
if not minetest.get_modpath("ethereal") then
	ARMOR_MATERIALS.crystal = nil
end

-- override hot nodes so they do not hurt player anywhere but mod
if ARMOR_FIRE_PROTECT == true then
	minetest.after(2, function()
		for _, row in ipairs(ARMOR_FIRE_NODES) do
			if minetest.registered_nodes[row[1]] then
				minetest.override_item(row[1], {damage_per_second = 0, radioaktive = 0})
			end
		end
	end)
end

local time = 0

armor = {
	player_hp = {},
	elements = {"head", "torso", "legs", "feet"},
	physics = {"jump","speed","gravity"},
	formspec = "size[8,8.5]list[detached:player_name_armor;armor;0,1;2,3;]"
        .."list[detached:player_name_armor;arm2;6,2;1,1;]"
		.."image[2,0.75;2,4;armor_preview]"
		.."list[current_player;main;0,4.5;8,4;]"
		.."list[current_player;craft;4,1;3,3;]"
		.."list[current_player;craftpreview;7,2;1,1;]",
	textures = {},
	default_skin = "character",
	version = "0.4.3",
}

if minetest.get_modpath("inventory_plus") then
	inv_mod = "inventory_plus"
	armor.formspec = "size[10,9.5]button[0,0;2,0.5;inven;Back]"
		.."button[2,0;2,0.5;main;Main]"
        .."background[10,9.5;1,1;gui_formbg.png;true]"
        .."listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"
        .."bgcolor[#080808BB;true]"
		.."list[detached:player_name_armor;armor;0,1;1,4;]"
		.."list[detached:player_name_armor;armor;1,2.5;1,1;4]"
		.."image[2.5,0.75;2,4;armor_preview]"
		.."label[4.5,1;Level: armor_level]"
		.."label[4.5,1.5;Heal:  armor_heal]"
		.."label[4.5,2;Fire:  armor_fire]"
        .."label[4.5,2.5.5;Speed:  armor_speed]"
		.."label[4.5,3;Jump:  armor_jump]"
		.."label[8,3;Armor key]"
        .."label[5.9,3;Protectionkey]"
        .."list[current_player;main;1,5.5;8,1;]"
		.."list[current_player;main;1,6.75;8,3;8]"
		.."list[current_player;arm;8,2;1,1;]"
        .."list[detached:player_name_armor;arm2;6,2;1,1;]"

elseif minetest.get_modpath("unified_inventory") then
	inv_mod = "unified_inventory"
	unified_inventory.register_button("armor", {
		type = "image",
		image = "inventory_plus_armor.png",
	})
	unified_inventory.register_page("armor", {
		get_formspec = function(player)
			local name = player:get_player_name()
			local formspec = "background[0.06,0.99;7.92,7.52;3d_armor_ui_form.png]"
				.."label[0,0;Armor]"
				.."list[detached:"..name.."_armor;armor;0,1;2,3;]"
				.."image[2.5,0.75;2,4;"..armor.textures[name].preview.."]"
				.."label[5,1;Level: "..armor.def[name].level.."]"
				.."label[5,1.5;Heal:  "..armor.def[name].heal.."]"
				.."label[5,2;Fire:  "..armor.def[name].fire.."]"
			return {formspec=formspec}
		end,
	})
elseif minetest.get_modpath("inventory_enhanced") then
	inv_mod = "inventory_enhanced"
end

if minetest.get_modpath("skins") then
	skin_mod = "skins"
elseif minetest.get_modpath("simple_skins") then
	skin_mod = "simple_skins"
elseif minetest.get_modpath("u_skins") then
	skin_mod = "u_skins"
elseif minetest.get_modpath("wardrobe") then
	skin_mod = "wardrobe"
end

armor.def = {
	state = 0,
	count = 0,
}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.armoff then
		
		local player_inv = player:get_inventory()
		player_inv:set_size("am", 1)
		local type = player:get_inventory():get_stack("arm",1):get_name()
		if type == "tutorial:armor_key" then
			player_inv:set_stack("am", 1, "default:dirt")
		else
		end
		armor:set_player_armor(player)
		armor:update_inventory(player)
		local name = player:get_player_name()
		local formspec = armor:get_armor_formspec(name)
		if inv_mod == "inventory_plus" then
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_armor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		end
	end
	if fields.armon then
		
		local player_inv = player:get_inventory()
		player_inv:set_size("am", 1)
		player_inv:set_stack("am", 1, nil)
		armor:set_player_armor(player)
		armor:update_inventory(player)
		local name = player:get_player_name()
		local formspec = armor:get_armor_formspec(name)
		if inv_mod == "inventory_plus" then
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_armor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		end
	end
end)
armor.update_player_visuals = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if self.textures[name] then
		default.player_set_textures(player, {
			self.textures[name].skin,
			self.textures[name].armor,
			self.textures[name].wielditem,
		})
	end
end

armor.set_player_armor = function(self, player)
	local name, player_inv = armor:get_valid_player(player, "[set_player_armor]")
	if not name then
		return
	end
	local armor_texture = "3d_armor_trans.png"
	local armor_level = 0
	local armor_heal = 0
	local armor_fire = 0
	local state = 0
	local items = 0
	local elements = {}
	local textures = {}
	local physics_o = {speed=1,gravity=1,jump=1}
	local material = {type=nil, count=1}
	local preview = armor:get_preview(name) or "character_preview.png"
	for _,v in ipairs(self.elements) do
		elements[v] = false
	end
	for i=1, 5 do
		local stack = player_inv:get_stack("armor", i)
		local item = stack:get_name()
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			for k, v in pairs(elements) do
				if v == false then
					local level = def.groups["armor_"..k]
					if level then
						local texture = item:gsub("%:", "_")
						local player_inv = player:get_inventory()
						local coun = player_inv:get_stack("am", 1):get_count()
						if coun == 0 then
							table.insert(textures, texture..".png")
						else
						end
						preview = preview.."^"..texture.."_preview.png"
						armor_level = armor_level + level
						state = state + stack:get_wear()
						items = items + 1
						local heal = def.groups["armor_heal"] or 0
						armor_heal = armor_heal + heal
						local fire = def.groups["armor_fire"] or 0
						armor_fire = armor_fire + fire
						for kk,vv in ipairs(self.physics) do
							local o_value = def.groups["physics_"..vv]
							if o_value then
								physics_o[vv] = physics_o[vv] + o_value
							end
						end
						local mat = string.match(item, "%:.+_(.+)$")
						if material.type then
							if material.type == mat then
								material.count = material.count + 1
							end
						else
							material.type = mat
						end
						elements[k] = true
					end
				end
			end
		end
	end
	armor_level = armor_level * ARMOR_LEVEL_MULTIPLIER
    armor_heal = armor_heal * ARMOR_HEAL_MULTIPLIER
    local player_inv = player:get_inventory()
    local arm = player_inv:get_stack("arm2", 1):get_name()
    if arm == "tutorial:protection_schluessel1" then
        armor_level = armor_level+armor_level*0.1
        armor_heal = armor_heal+armor_heal*0.1
        armor_fire = armor_fire+armor_fire*0.1
    elseif arm == "tutorial:protection_schluessel2" then
        armor_level = armor_level+armor_level*0.2
        armor_heal = armor_heal+armor_heal*0.2
        armor_fire = armor_fire+armor_fire*0.2
    elseif arm == "tutorial:protection_schluessel3" then
        armor_level = armor_level+armor_level*0.3
        armor_heal = armor_heal+armor_heal*0.3
        armor_fire = armor_fire+armor_fire*0.3
    end
	
	if #textures > 0 then
		armor_texture = table.concat(textures, "^")
	end
	local armor_groups = {fleshy=100}
	if armor_level > 0 then
		armor_groups.level = math.floor(armor_level / 100)
		armor_groups.fleshy = 100 - armor_level
	end
	player:set_armor_groups(armor_groups)
	player:set_physics_override(physics_o)
	self.textures[name].armor = armor_texture
	self.textures[name].preview = preview
	self.def[name].state = state
	self.def[name].count = items
	self.def[name].level = armor_level
	self.def[name].heal = armor_heal
	self.def[name].jump = physics_o.jump
	self.def[name].speed = physics_o.speed
	self.def[name].gravity = physics_o.gravity
	self.def[name].fire = armor_fire
	self:update_player_visuals(player)
end

armor.update_armor = function(self, player, dtime)
	local name, player_inv, armor_inv, pos = armor:get_valid_player(player, "[update_armor]")
	if not name then
		return
	end
	local hp = player:get_hp() or 0
	if ARMOR_FIRE_PROTECT == true then
		pos.y = pos.y + 1.4 -- head level
		local node_head = minetest.get_node(pos).name
		pos.y = pos.y - 1.2 -- feet level
		local node_feet = minetest.get_node(pos).name
		-- is player inside a hot node?
		for _, row in ipairs(ARMOR_FIRE_NODES) do
			-- check for fire protection, if not enough then get hurt
			if row[1] == node_head or row[1] == node_feet then
				if hp > 0 and armor.def[name].fire < row[2] then
					player:set_hp(hp - row[3] * dtime)
					break
				end
			end
		end
	end	
	if hp == 0 or hp == self.player_hp[name] then
		return
	end
	if self.player_hp[name] > hp then
		local heal_max = 0
		local state = 0
		local items = 0
		for i=1, 5 do
			local stack = player_inv:get_stack("armor", i)
			if stack:get_count() > 0 then
				local use = stack:get_definition().groups["armor_use"] or 0
				local heal = stack:get_definition().groups["armor_heal"] or 0
				local item = stack:get_name()
				stack:add_wear(use)
				armor_inv:set_stack("armor", i, stack)
				player_inv:set_stack("armor", i, stack)
				state = state + stack:get_wear()
				items = items + 1
				if stack:get_count() == 0 then
					local desc = minetest.registered_items[item].description
					if desc then
						minetest.chat_send_player(name, "Your "..desc.." got destroyed!")
					end
					self:set_player_armor(player)
					armor:update_inventory(player)
				end
				heal_max = heal_max + heal
			end
		end
        local player_inv = player:get_inventory()
        local arm = player_inv:get_stack("arm2", 1):get_name()
        if arm == "tutorial:protection_schluessel1" then
            heal_max = heal_max+heal_max*0.1
        elseif arm == "tutorial:protection_schluessel2" then
            heal_max = heal_max+heal_max*0.2
        elseif arm == "tutorial:protection_schluessel3" then
            heal_max = heal_max+heal_max*0.3
        end
		self.def[name].state = state
		self.def[name].count = items
		heal_max = heal_max * ARMOR_HEAL_MULTIPLIER
        if heal_max == nil or heal_max == 0 then
            heal_max = 1
        end
		if heal_max > math.random(heal_max + math.floor(heal_max*0.1)) then
			player:set_hp(self.player_hp[name])
			return
		end
	end
	self.player_hp[name] = hp
end

armor.get_player_skin = function(self, name)
	local skin = nil
	if skin_mod == "skins" or skin_mod == "simple_skins" then
		skin = skins.skins[name]
	elseif skin_mod == "u_skins" then
		skin = u_skins.u_skins[name]
	elseif skin_mod == "wardrobe" then
		skin = string.gsub(wardrobe.playerSkins[name], "%.png$","")
	end
	return skin or armor.default_skin
end

armor.get_preview = function(self, name)
	if skin_mod == "skins" then
		return armor:get_player_skin(name).."_preview.png"
	end
end

armor.get_armor_formspec = function(self, name)
	if not armor.textures[name] then
		minetest.log("error", "3d_armor: Player texture["..name.."] is nil [get_armor_formspec]")
		return ""
	end
	if not armor.def[name] then
		minetest.log("error", "3d_armor: Armor def["..name.."] is nil [get_armor_formspec]")
		return ""
	end
	local player = minetest.get_player_by_name(name)
	local player_inv = player:get_inventory()
	local am = player_inv:get_stack("am", 1):get_count()
	local formspec = armor.formspec:gsub("player_name", name)
	formspec = formspec:gsub("armor_preview", armor.textures[name].preview)
	formspec = formspec:gsub("armor_level", armor.def[name].level)
	formspec = formspec:gsub("armor_heal", armor.def[name].heal)
	formspec = formspec:gsub("armor_fire", armor.def[name].fire)
 formspec = formspec:gsub("armor_jump", (armor.def[name].jump-1)*4)
 formspec = formspec:gsub("armor_speed", (armor.def[name].speed-1)*4)
	if am == 1 then
		formspec = formspec .."button[7.5,3.7;2,0.5;armon;armor on]"
	else
		formspec = formspec .."button[7.5,3.7;2,0.5;armoff;armor off]"
		
	end
	return formspec
end
armor.update_inventory = function(self, player)
	local name = armor:get_valid_player(player, "[set_player_armor]")
	if not name or inv_mod == "inventory_enhanced" then
		return
	end
	if inv_mod == "unified_inventory" then
		if unified_inventory.current_page[name] == "armor" then
			unified_inventory.set_inventory_formspec(player, "armor")
		end
	else
		local formspec = armor:get_armor_formspec(name)
		if inv_mod == "inventory_plus" then
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_armor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		else
			player:set_inventory_formspec(formspec)
		end
	end
end

armor.get_valid_player = function(self, player, msg)
	msg = msg or ""
	if not player then
		minetest.log("error", "3d_armor: Player reference is nil "..msg)
		return
	end
	local name = player:get_player_name()
	if not name then
		minetest.log("error", "3d_armor: Player name is nil "..msg)
		return
	end
	local pos = player:getpos()
	local player_inv = player:get_inventory()
	local armor_inv = minetest.get_inventory({type="detached", name=name.."_armor"})
	if not pos then
		minetest.log("error", "3d_armor: Player position is nil "..msg)
		return
	elseif not player_inv then
		minetest.log("error", "3d_armor: Player inventory is nil "..msg)
		return
	elseif not armor_inv then
		minetest.log("error", "3d_armor: Detached armor inventory is nil "..msg)
		return
	end
	return name, player_inv, armor_inv, pos
end

-- Register Player Model

default.player_register_model("3d_armor_character.b3d", {
	animation_speed = 30,
	textures = {
		armor.default_skin..".png",
		"3d_armor_trans.png",
		"3d_armor_trans.png",
	},
	animations = {
		stand = {x=0, y=79},
		lay = {x=162, y=166},
		walk = {x=168, y=187},
		mine = {x=189, y=198},
		walk_mine = {x=200, y=219},
		sit = {x=81, y=160},
	},
})

-- Register Callbacks

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = armor:get_valid_player(player, "[on_player_receive_fields]")
	if fields.armor then
		local formspec = armor:get_armor_formspec(name)
        armor:set_player_armor(player)
		armor:update_inventory(player)
		local name = player:get_player_name()
		local formspec = armor:get_armor_formspec(name)
		if inv_mod == "inventory_plus" then
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_armor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		end
		inventory_plus.set_inventory_formspec(player, formspec)
		return
	end
	for field, _ in pairs(fields) do
		if string.find(field, "skins_set") then
			minetest.after(0, function(player)
				local skin = armor:get_player_skin(name)
				armor.textures[name].skin = skin..".png"
				armor:set_player_armor(player)
			end, player)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	default.player_set_model(player, "3d_armor_character.b3d")
	local name = player:get_player_name()
	local player_inv = player:get_inventory()
	local armor_inv = minetest.create_detached_inventory(name.."_armor", {
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local plaver_inv = player:get_inventory()
			local stack = inv:get_stack(to_list, to_index)
			player_inv:set_stack(to_list, to_index, stack)
			player_inv:set_stack(from_list, from_index, nil)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		allow_put = function(inv, listname, index, stack, player)
			if listname == "armor" then
                if index == 1 and stack:get_definition().groups.armor_head then
			      return 1
			    elseif index == 2 and stack:get_definition().groups.armor_torso then
			      return 1
			    elseif index == 3 and stack:get_definition().groups.armor_legs then
			      return 1
			    elseif index == 4 and stack:get_definition().groups.armor_feet then
			      return 1
		        elseif index == 5 and stack:get_definition().groups.armor_shield then
			      return 1
			    else
			      return 0
			    end
            else
                return 1
            end

		end,
		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			if listname == "armor" then
                if index == 1 and stack:get_definition().groups.armor_head then
			      return 1
			    elseif index == 2 and stack:get_definition().groups.armor_torso then
			      return 1
			    elseif index == 3 and stack:get_definition().groups.armor_legs then
			      return 1
			    elseif index == 4 and stack:get_definition().groups.armor_feet then
			      return 1
		        elseif index == 5 and stack:get_definition().groups.armor_shield then
			      return 1
			    else
			      return 0
			    end
            else
                return 1
            end
		end,
	})
	armor_inv:set_size("armor", 5)
    armor_inv:set_size("arm2", 1)
    player_inv:set_size("arm", 1)
    player_inv:set_size("arm2", 1)
	player_inv:set_size("armor", 5)
    
    local stack = player_inv:get_stack("arm2", 1)
	armor_inv:set_stack("arm2", 1, stack)
	for i=1, 5 do
		local stack = player_inv:get_stack("armor", i)
		armor_inv:set_stack("armor", i, stack)
	end	

	-- Legacy support, import player's armor from old inventory format
	for _,v in pairs(armor.elements) do
		local list = "armor_"..v
		armor_inv:add_item("armor", player_inv:get_stack(list, 1))
		player_inv:set_stack(list, 1, nil)
	end
	-- TODO Remove this on the next version upate

	armor.player_hp[name] = 0
	armor.def[name] = {
		state = 0,
		count = 0,
		level = 0,
		heal = 0,
		jump = 1,
		speed = 1,
		gravity = 1,
		fire = 0,
	}
	armor.textures[name] = {
		skin = armor.default_skin..".png",
		armor = "3d_armor_trans.png",
		wielditem = "3d_armor_trans.png",
		preview = armor.default_skin.."_preview.png",
	}
	if skin_mod == "skins" then
		local skin = skins.skins[name]
		if skin and skins.get_type(skin) == skins.type.MODEL then
			armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "simple_skins" then
		local skin = skins.skins[name]
		if skin then
		    armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "u_skins" then
		local skin = u_skins.u_skins[name]
		if skin and u_skins.get_type(skin) == u_skins.type.MODEL then
			armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "wardrobe" then
		local skin = wardrobe.playerSkins[name]
		if skin then
			armor.textures[name].skin = skin
		end
	end
	if minetest.get_modpath("player_textures") then
		local filename = minetest.get_modpath("player_textures").."/textures/player_"..name
		local f = io.open(filename..".png")
		if f then
			f:close()
			armor.textures[name].skin = "player_"..name..".png"
		end
	end
	for i=1, ARMOR_INIT_TIMES do
		minetest.after(ARMOR_INIT_DELAY * i, function(player)
			armor:set_player_armor(player)
			if not inv_mod then
				armor:update_inventory(player)
			end
		end, player)
	end
end)

if ARMOR_DROP == true or ARMOR_DESTROY == true then
	armor.drop_armor = function(pos, stack)
		local obj = minetest.add_item(pos, stack)
		if obj then
			local x = math.random(1, 5)
			if math.random(1,2) == 1 then
				x = -x
			end
			local z = math.random(1, 5)
			if math.random(1,2) == 1 then
				z = -z
			end
			obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})
		end
	end
	minetest.register_on_dieplayer(function(player)
		local name, player_inv, armor_inv, pos = armor:get_valid_player(player, "[on_dieplayer]")
		if not name then
			return
		end
		local drop = {}
		for i=1, player_inv:get_size("armor") do
			local stack = armor_inv:get_stack("armor", i)
			if stack:get_count() > 0 then
				table.insert(drop, stack)
				armor_inv:set_stack("armor", i, nil)
				player_inv:set_stack("armor", i, nil)
			end
		end
		armor:set_player_armor(player)
		if inv_mod == "unified_inventory" then
			unified_inventory.set_inventory_formspec(player, "craft")
		elseif inv_mod == "inventory_plus" then
			local formspec = inventory_plus.get_formspec(player,"main")
			inventory_plus.set_inventory_formspec(player, formspec)
		else
			armor:update_inventory(player)
		end
		if ARMOR_DESTROY == false then
			minetest.after(ARMOR_BONES_DELAY, function()
				pos = vector.round(pos)
				local node = minetest.get_node(pos)
				if node then
					if node.name == "bones:bones" then
						local meta = minetest.get_meta(pos)
						local owner = meta:get_string("owner")
						local inv = meta:get_inventory()
						for _,stack in ipairs(drop) do
							if name == owner and inv:room_for_item("main", stack) then
								inv:add_item("main", stack)
							else
								armor.drop_armor(pos, stack)
							end
						end
					end
				else
					for _,stack in ipairs(drop) do
						armor.drop_armor(pos, stack)
					end
				end
			end)
		end
	end)
end

minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time > ARMOR_UPDATE_TIME then
		for _,player in ipairs(minetest.get_connected_players()) do
			armor:update_armor(player, time)
		end
		time = 0
	end
end)

