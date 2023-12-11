function tableContainsKey(table, key)
  for k, _ in pairs(table) do
    if k == key then
      return true
    end
  end
  return false
end

function getTableDiff(originalTable, keysToRemove)
  local resultTable = {}
  for _, key in ipairs(originalTable) do
    if not tableContainsKey(keysToRemove, key) then
      table.insert(resultTable, key)
    end
  end
  return resultTable
end

function tableContainsValue(table, val)
  for _, v in pairs(table) do
    if v == val then
      return true
    end
  end
  return false
end

function tableContains(table, value)
  for i = 1,#table do
    if (table[i] == value) then
      return true
    end
  end
  return false
end



local DEBUG_RECIPE_REQUIRES = false
function recipe_requires(recipe, dep)
    assert(recipe ~= nil)
    assert(dep ~= nil)

    if DEBUG_RECIPE_REQUIRES then
	print('recipe_requires(recipe='..recipe_to_string(recipe)..', dep='..dep..')')
    end

    return list_nd_contains(recipe.recipe, dep)
end

function list_nd_contains(list, value)
    if value == list then return true end

    if type(list) ~= "table" then return false end

    for _, item in ipairs(list) do
        if list_nd_contains(value, item) then
            return true
        end
    end
    return false
end

function list_nd_equals(a, b)
	if a == b then return true end

	if type(a) ~= "table" then return false end
	if type(b) ~= "table" then return false end

	if #a ~= #b then return false end

	for _, item in pairs(a) do
		if not list_nd_contains(b, item) then return false end
	end
	--for _, item in pairs(b) do
	--	if not list_nd_contains(a, item) then return false end
	--end
	return true
end

local DEBUG_MAKE_FAKEDEF = false
local TEST_MAKE_FAKEDEF  = true
function make_fakedef(name)
	if DEBUG_MAKE_FAKEDEF then
	print('make_fakedef('..list_nd_to_string(name)..')')
	end
	local def = table.copy(minetest.registered_items[name])
	assert(def ~= nil)
	assert(def ~= nil)
	if DEBUG_MAKE_FAKEDEF then
	print('def: '..table.concat(def))
	end

	if TEST_MAKE_FAKEDEF then
		if def.description ~= nil then
			def.description = 'Fake '..def.description
		else
			def.description = 'Fake Item'
		end
		print('new desc: '..def.description)
	end
	--for a, b in pairs(def) do
	--	print(a..' : '..b)
	--end

	-- TODO cause faulty behaviors
	return def
end

local old_register_craft = minetest.register_craft
local substitutions      = {
	["default:diamond"]      = "fakery:diamond",
	["default:mese_crystal"] = "fakery:mese",
}

function product(lists, vals)
	local new_lists = {}
	for _, list in ipairs(lists) do
		for _, val in ipairs(vals) do
			local new_list = table.copy(list)
			table.insert(new_list, val)
			table.insert(new_lists, new_list)
		end
	end
	return new_lists
end

local DEBUG_MAKE_SUBSTITUTIONS_HELPER = false
function make_substitutions_helper(convert_to, recipe)
    assert(recipe ~= nil)
    if DEBUG_MAKE_SUBSTITUTIONS_HELPER then print('make_substitutions_helper(' .. list_nd_to_string(recipe) .. ')') end

    if type(recipe) == "string" then
	    if tableContainsKey(substitutions, recipe) then
		    if DEBUG_MAKE_SUBSTITUTIONS_HELPER then print('make_substitutions_helper() SUCCESS '..recipe..' ==> '..substitutions[recipe]) end
		    return {
			    substitutions[recipe],
			    recipe,
		    }
	    end
	    if DEBUG_MAKE_SUBSTITUTIONS_HELPER then print('make_substitutions_helper() FAILURE '..recipe) end
	    return { recipe, }
    end
    assert(type(recipe) == "table")

    local recipes = {{}}
    for _, item in ipairs(recipe) do
        local items = make_substitutions_helper(convert_to, item)
	--local temp  = product(recipes, items)
	--table.insert(recipes, temp)
	recipes = product(recipes, items)
    end

    if DEBUG_MAKE_SUBSTITUTIONS_HELPER then print('make_substitutions_helper() LEAVE loop') end
    for _, v in ipairs(recipes) do
	    if DEBUG_MAKE_SUBSTITUTIONS_HELPER then print('make_substitutions_helper() LEAVE: '..recipe_to_string(v)) end
    end

    return recipes
end
function convert_output(convert_to, recipe)
    local new_recipe  = table.copy(recipe)
    local new_output  = ItemStack(recipe.output)
    new_output:set_name(convert_to)
    new_recipe.output = new_output:to_string()
    return new_recipe
end
local DEBUG_MAKE_SUBSTITUTIONS = false
function make_substitutions(convert_to, recipe)
    local sub_recipes = make_substitutions_helper(convert_to, recipe.recipe)

    -- filter out the one that has no subs
    local fil_recipes = {}
    for _, sub_recipe in ipairs(sub_recipes) do
	if not list_nd_equals(sub_recipe, recipe.recipe) then
	    if DEBUG_MAKE_SUBSTITUTIONS then print('make_substitutions() filter SUCCESS: '..recipe_to_string(sub_recipe)) end
	    table.insert(fil_recipes, sub_recipe)
        else
	    if DEBUG_MAKE_SUBSTITUTIONS then print('make_substitutions() filter FAILURE: '..recipe_to_string(sub_recipe)) end
	end
    end
   
    local new_recipes = {}
    for _, fil_recipe in ipairs(fil_recipes) do
    	local new_recipe  = convert_output(convert_to, recipe)
	new_recipe.recipe = fil_recipe
	if DEBUG_MAKE_SUBSTITUTIONS then print('make_substitutions() new recipe: '..recipe_to_string(new_recipe)) end
        table.insert(new_recipes, new_recipe) 
    end
    return new_recipes
end


-- Helper function to print a recipe in a readable format
function recipe_to_string(recipe)
    local recipe_str = ""
    for k, v in pairs(recipe) do
        if k == "recipe" then
            recipe_str = recipe_str .. k .. ' : ' .. list_nd_to_string(v) .. ', '
        elseif type(v) == "table" then
            recipe_str = recipe_str .. k .. ' : ' .. table.concat(v) .. ', '
        else
            recipe_str = recipe_str .. k .. ' : ' .. v .. ', '
        end
    end
    return recipe_str
end

-- Convert a recipe to string representation
function list_nd_to_string(recipe)
    if type(recipe) ~= "table" then return recipe end
    local recipe_str = ""
    for _, row in ipairs(recipe) do
        recipe_str = recipe_str .. list_nd_to_string(row) .. ','
    end
    return '{'..recipe_str..'}'
end

local def = table.copy(minetest.registered_items["default:mese_crystal_fragment"])
if TEST_MAKE_FAKEDEF then def.description = 'Fake '..def.description end
minetest.register_craftitem("iafakery:mese_crystal_fragment", def)

def = table.copy(minetest.registered_items["default:mese"])
if TEST_MAKE_FAKEDEF then def.description = 'Fake '..def.description end
minetest.register_node("iafakery:mese", def)

def = table.copy(minetest.registered_items["default:diamondblock"])
if TEST_MAKE_FAKEDEF then def.description = 'Fake '..def.description end
minetest.register_node("iafakery:diamondblock", def)

-- TODO allow subs
--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'fakery:mese',
  recipe        = {
      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',

      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',

      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',
      'iafakery:mese_crystal_fragment',
  },
})
--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'fakery:mese 9',
  recipe        = {
      'iafakery:mese',
  },
})

-- TODO allow subs
--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'iafakery:mese',
  recipe        = {
	  'fakery:mese',
	  'fakery:mese',
	  'fakery:mese',

	  'fakery:mese',
	  'fakery:mese',
	  'fakery:mese',

	  'fakery:mese',
	  'fakery:mese',
	  'fakery:mese',
  },
})
--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'iafakery:mese_crystal_fragment 9',
  recipe        = {
	  'fakery:mese',
  },
})

--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'fakery:diamond 9',
  recipe        = {
      'iafakery:diamondblock',
  },
})

-- TODO allow subs
--minetest.register_craft({
old_register_craft({
  type          = "shapeless",
  output        = 'iafakery:diamondblock',
  recipe        = {
	  'fakery:diamond',
	  'fakery:diamond',
	  'fakery:diamond',

	  'fakery:diamond',
	  'fakery:diamond',
	  'fakery:diamond',

	  'fakery:diamond',
	  'fakery:diamond',
	  'fakery:diamond',
  },
})

-- TODO powered rail
-- TODO mese lamp
-- TODO post lights
-- TODO mese tools


local DEBUG_NEW_REGISTER_CRAFT = true
function new_register_craft(recipe)
	assert(recipe ~= nil)
	--if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() recipe: '..recipe_to_string(recipe)) end

	if recipe.output == nil then -- fuel
		if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() -1 A') end
		old_register_craft(recipe)
		return
	end
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() -1 B') end

	local itemstack = ItemStack(recipe.output)
	local name      = itemstack:get_name()
	assert(name   ~= nil)
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() name: '..name) end
	if name == "default:diamond" -- TODO handle other fake types
	or name == "default:mese_crystal"
	then
		if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 0 A') end
		old_register_craft(recipe)
		return
	end
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 0 B') end

	local modname = string.match(name,  '([^:]+)')
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() modname: '..modname) end
	--local itmname = string.match(name, ':([^:]+)')
	--assert(modname ~= nil)
	--assert(itmname ~= nil)
	--assert(modname ~= "")
	--assert(itmname ~= "")
	if modname == 'homedecor' then return end -- whatever
	if modname == 'jumpdrive' then return end -- whatever
	if modname == 'iafakery' then
		if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 1 A') end
		old_register_craft(recipe)
		return
	end
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 1 B') end

	if  not recipe_requires(recipe, 'default:diamond')
	and not recipe_requires(recipe, 'default:mese_crystal') then
		if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 2 A') end
		old_register_craft(recipe)
		return
	end
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 2 B') end

	local fake_def = make_fakedef(name)
	assert(fake_def ~= nil)

	-- TODO test whether type is node,
	-- else tool & craftitems should be handled the same ?
	--local convert_to = 'iafakery:'..modname..'_'..itmname
	local convert_to = name..'_iafakery'
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() convert_to: '..convert_to) end
	minetest.register_craftitem(convert_to, fake_def)

	if DEBUG_NEW_REGISTER_CRAFT then print('calling make_substitutions() with recipe '..recipe_to_string(recipe)) end
	local recipes = make_substitutions(convert_to, recipe)
	for _, fake_recipe in ipairs(recipes) do
		if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 3 loop: '..recipe_to_string(fake_recipe)) end
		assert(fake_recipe ~= nil)
		assert(not list_nd_equals(fake_recipe.recipe, recipe.recipe))
		old_register_craft(fake_recipe)
	end
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 4 orig '..recipe_to_string(recipe)) end
	old_register_craft(recipe)
	if DEBUG_NEW_REGISTER_CRAFT then print('register_craft() 5') end
end


minetest.register_craft = new_register_craft

print ("[MOD] IA Fakery loaded")
