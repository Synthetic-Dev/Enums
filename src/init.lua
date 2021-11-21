local Enums = { }

local tempEnumItem = newproxy(true)
do
	local meta = getmetatable(tempEnumItem)
	meta.__index = {
		Name = "name";
		Value = 0;
		EnumType = { } :: Enum;
	}
	meta.__newindex = function()
		error("EnumItem is read-only")
	end
	meta.__tostring = function()
		return string.format("%s.%s", "enumName", "name")
	end
end

export type EnumItem = typeof(tempEnumItem)
export type Enum = {
	[string]: EnumItem;
	ByValue: (value: any) -> EnumItem;
	GetEnumItems: () -> { [number]: EnumItem; };
}

export type InitEnumValues = { [any]: string; }

local function EnumItem(
	name: string,
	value: number,
	enumName: string,
	enumType: Enum
): EnumItem
	local enumItem = newproxy(true)
	local meta = getmetatable(enumItem)
	meta.__index = {
		Name = name;
		Value = value;
		EnumType = enumType;
	}
	meta.__newindex = function()
		error("EnumItem is read-only")
	end
	meta.__tostring = function()
		return string.format("%s.%s", enumName, name)
	end
	return enumItem
end

local function NewEnum(name: string, values: InitEnumValues): Enum
	local enum = { }
	local items = { }

	for value, valueName in pairs(values) do
		local item = EnumItem(valueName, value, name, enum)
		table.insert(items, item)
		enum[valueName] = item
	end

	return setmetatable(enum, {
		__index = function(self, index)
			if index == "ByValue" then
				return function(_s, value)
					index = rawget(values, value)
					if not index then
						error(
							string.format(
								"'%s' does not have an enum item with value '%s'",
								name,
								tostring(value)
							),
							2
						)
					end
					return self[index]
				end
			elseif index == "GetEnumItems" then
				return function(_s)
					return items
				end
			end

			local value = rawget(self, index)
			if not value then
				error(
					string.format(
						"'%s' is not an enum item of '%s'",
						tostring(index),
						name
					),
					2
				)
			end
			return value
		end;

		__newindex = function()
			error("Enum is read-only")
		end;
	}) :: Enum
end

local function AddEnum(
	t: { [any]: any; },
	name: string,
	values: InitEnumValues
): Enum
	local enum = NewEnum(name, values)
	t[name] = enum
	return enum
end

Enums.new = NewEnum
Enums.add = AddEnum

return Enums
