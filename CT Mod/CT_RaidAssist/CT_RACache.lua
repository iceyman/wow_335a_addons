CT_RA_NumGroups = 8;  -- When sorting by group this is 8, when sorting by class this is the number of classes in the game.
CT_RA_MaxGroups = 10;  -- This is the maximum number of possible groups (when sorting by group or class).

function CT_RA_UnitName(unit)
	local name, realm = UnitName(unit);
	if (name and realm and realm ~= "") then
		return name .. "-" .. realm;
	end
	return name;
end

-- Inner cache metatable 
local subMeta = { 
-- Given a name, append it to the parent frame name, and then return
-- the result (cache it if it's found) 
	__index = function(t, name)
		local tn = type(name);
		if (tn == "string" or tn == "number") then
			local realName = t._frameName .. name;
			local realFrame = getglobal(realName);
			if (realFrame) then
				t[name] = realFrame;
			end return realFrame;
		end
	end 
};

local topMeta = { 
	-- Given a frame or a frame name, create (or return) the subcache
	-- for that frame.
	__index = function(t, frame)
		local tf = type(frame);
		if (tf == "string") then
			-- If we're passed a frame name, look up the frame behind
			-- it and if it's found, get its subcache
			local realFrame = getglobal(frame);
			-- Prevent infinite looping
			if (type(realFrame)=="table") then
				local ret = t[realFrame];
				if (ret) then
					t[frame] = ret;
				end
				return ret;
			end
		elseif (tf == "table") then 
			-- Must create a new caching subtable if frame is an
			-- actual Frame.
			local gn = frame.GetName;
			if (gn) then
				local ret = {};
				ret._frame = frame;
				ret._frameName = gn(frame);
				setmetatable(ret, subMeta);
				t[frame] = ret;
				return ret;
			end
		end 
	end
};
 -- Create a fresh subframe cache and return it.
local function CreateSubframeCache()
	local ret = {};
	setmetatable(ret, topMeta);
	return ret;
end

CT_RA_Cache = CreateSubframeCache();