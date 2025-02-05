------------------------------------------------
--                 CT_MailMod                 --
--                                            --
-- Mail several items at once with almost no  --
-- effort at all. Also takes care of opening  --
-- several mail items at once, reducing the   --
-- time spent on maintaining the inbox for    --
-- bank mules and such.                       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G["CT_MailMod"];

--------------------------------------------
-- General Logging

-- Log entry timestamps:
--
--   The timestamp used in log entries created prior to CT_MailMod 3.210
--   was intended to be the time that the mail was sent. However, the
--   calculation was not correct, and the resulting times could be off
--   by as much as plus or minus 30 days (it depended on when the user
--   opened the message during the mail's expiry period).
--
--   This was the old calculation:
--      module:getTimeFromOffset(-mail.timeleft)
--
--   In order to properly calculate the sent time, you need to know
--   the maximum expiry time for every possible type of mail.
--   This is what would have worked (if mail.maxtimeleft could be
--   determined):
--      module:getTimeFromOffset(-(mail.maxtimeleft - mail.timeleft))
--
--   However, the maximum expiry time is not provided by the server, and
--   it can vary from 31 days to just a few days or less, depending on
--   what type of mail you are dealing with (auction house mail, mail your
--   friend sent you, mail that Blizzard sent you, a new pet you got in the
--   mail, temporary invoices, etc).
--
--   As of CT_MailMod 3.210, new log entries are recorded in the log with
--   a timestamp equal to the time that the log entry was created.

local function encodeLogEntry(success, type, mail, message)
	-- Encode a log entry
	local entry;
	local receiver, sender;

	if (mail) then
		if (type == "returned") then
			-- For mail being returned, log the entry as
			-- coming from the person doing the returning.
			-- (the receiver becomes the sender of the returned mail)
			-- (this is the same as if they had opened it and sent a new mail)
			receiver = mail.sender;
			sender = mail.receiver;
		else
			receiver = mail.receiver;
			sender = mail.sender;
		end
	end

	if ( success and mail ) then
		-- Format:
		--   success, type, receiver, sender, money, timestamp, num items (N)
		--   subject, item_1 string, item_2, string, ..., item_N string
		--
		local numItems = 0;
		local items = "";
		local money = mail.logMoney;
		local list = mail.logItems;
		if (list) then
			-- Build list of items taken so far
			local link, count;
			local entry;
			numItems = #list;
			for i = 1, numItems do
				entry = list[i];
				items = items .. ("#%s/%d"):format(entry[1], entry[2]);  -- link, count
			end
		end
		money = money or 0;
		entry = ("1#%s#%s#%s#%d#%d#%d#%s"):format(type, receiver, sender, money, time(), numItems, mail.subject) .. items;

	elseif ( not success and message ) then
		if (not mail) then
			-- Old type "0" format: (no longer added to the log as of CT_MailMod 3.210)
			--   success, type, message
			-- entry = ("0#%s#%s"):format(type, module:getText(message));

			-- Type "3" format: (added as of CT_MailMod 3.210)
			--   success, type, timestamp, message
			entry = ("3#%s#%d#%s"):format(type, time(), module:getText(message));
		else
			-- Format:
			--   success, type, receiver, sender, subject, timestamp, message
			entry = ("2#%s#%s#%s#%s#%d#%s"):format(type, receiver, sender, mail.subject, time(), module:getText(message));
		end
	end

	return entry;
end

local function decodeLogEntry(logMsg)
	-- Decode a log entry
	local receiver, sender, subject, money, timestamp, numItems, items, message;

	local success, type, msg = logMsg:match("^(%d)#([^#]*)#(.*)$");
	if ( success == "1" ) then
		-- Success
		receiver, sender, money, timestamp, numItems, message = msg:match("^([^#]*)#([^#]*)#([^#]*)#([^#]*)#([^#]*)#(.*)$");
		subject, items = message:match("^(.-)#("..("[^#]+#"):rep(tonumber(numItems)-1).."[^#]+)$");
		if ( not items ) then
			subject = message;
			items = "";
		end
		if (items == "") then
			return true, type, nil, receiver, sender, subject, tonumber(money), tonumber(timestamp);
		else
			return true, type, nil, receiver, sender, subject, tonumber(money), tonumber(timestamp), ("#"):split(items);
		end

	elseif (success == "2") then
		-- New as of CT_MailMod 3.210
		-- Failure
		receiver, sender, subject, timestamp, message = msg:match("^([^#]*)#([^#]*)#([^#]*)#([^#]*)#(.*)$");
		return false, type, message, receiver, sender, subject, 0, tonumber(timestamp);

	elseif (success == "3") then
		-- New as of CT_MailMod 3.210
		-- Failure
		timestamp, message = msg:match("^([^#]*)#(.*)$");
		return false, type, message, nil, nil, nil, 0, tonumber(timestamp);

	else
		-- Type "0" record.
		-- As of CT_MailMod 3.210 these are no longer being added to the mail log (type "3" is now being added instead).
		-- This code is here to handle existing log entries, or future unknown record types.
		-- Failure
		return false, type, msg, nil, nil, nil, 0, 0;
	end
end

-- date("%a, %b %d %I:%M%p", time());

local function getLogTable()
	-- Obtain a reference to the mail log table.
	local log = module:getOption("mailLog") or { };
	module:setOption("mailLog", log);
	return log;
end

local function getLogEntry(id)
	-- Get the specified log entry from the mail log table.
	local log = getLogTable();
	return log[#log+1-id]; -- Reversed
end

function module:printLogMessage(success, mail, message)
	-- Print a message in the chat window.
	if (module.opt.printLog) then
		local message = module:getText(message);
		if (mail) then
			message = ("%s: %s"):format(mail:getName(), message);
		end
		(success and module.printformat or module.errorformat)("<MailMod> %s", message);
	end
end

local logSerial = 0;  -- Used to keep track of which mail object is associated with the most recent log entry.

local function writeLogEntry(self, type, success, mail, message)
	-- Write a log entry (it will either add a new one, or update the most recent one)
	if (not mail or (mail and mail.logPrint)) then
		-- Print a message in the chat window
		module:printLogMessage(success, mail, message);
	end
	if (module.opt.saveLog) then
		-- Encode the message, etc as a log entry.
		local entry = encodeLogEntry(success, type, mail, message);

		-- If this mail object is the same as the one associated with the most
		-- recent log entry then update that log entry, otherwise add a new log entry.
		local log = getLogTable();
		if (mail and mail.serial and mail.serial == logSerial and #log > 0) then
			log[#log] = entry;  -- Update the existing entry
		else
			tinsert(log, entry);  -- Add new entry
		end

		if (mail) then
			-- Remember the mail serial number associated with the most recent log entry.
			logSerial = mail.serial;
			-- Save the message
			mail.logMessage = message;
		else
			-- The most recent log entry does not belong to a mail object.
			logSerial = 0;
		end
		if (not success) then
			-- If the message just written was for a failure (error message),
			-- then ensure the next log entry will not replace the one that
			-- was just written.
			logSerial = 0;
		end
		-- Update the mail log display.
		module:updateMailLog();
	end
end

--------------------------------------------
-- Write pending log entry

function module:logPending(mail)
	if (mail and mail.logPending) then
		-- There is mail information that needs to be logged.
		local logFunc = mail.logFunc;
		if (logFunc) then
			logFunc(module, mail.logSuccess, mail, mail.logMessage);
		end
		mail.logPending = false;
		-- Can't clear the mail.logItems or mail.logMoney here,
		-- since taking items from the OpenMailFrame depends on
		-- maintaining those values while the user is taking items.
	end
end

--------------------------------------------
-- Incoming Mail Log

function module:logIncoming(success, mail, message)
	-- Log an incoming mail message.
	if (not module.opt.logOpenedMail) then
		-- User is not logging opened mail.
		return;
	end
	if (mail and not success) then
		-- We are dealing with a mail object and an error message.
		if (mail.logPending) then
			-- There is log information pending.
			-- We may need to create a log entry to record things taken so far.
			if (#mail.logItems > 0 or mail.logMoney ~= 0) then
				-- Add a log entry for the items/money that has been taken already.
				module:logPending(mail);
				-- Since we've just logged the pending items, and since we'll be
				-- writing an error message, we can go ahead and clear the .logItems
				-- and .logMoney values.
				mail.logItems = {};
				mail.logMoney = 0;
			end
			-- There is no longer anything pending to be logged,
			-- so reset the module.logPending flag.
			mail.logPending = false;
		end

		-- Reset the log serial number to 0 to ensure that the next log entry (the error message)
		-- does not replace the most recent log entry.
		logSerial = 0;

		-- Reset the mail.logPrint value to true.
		-- This will ensure that the error message will be displayed
		-- in chat (if the user has the option enabled).
		mail.logPrint = true;
	end
	writeLogEntry(module, "incoming", success, mail, message);
end

--------------------------------------------
-- Returned Mail Log

function module:logReturned(success, mail, message)
	-- Log a returned mail message.
	if (module.opt.logReturnedMail) then
		writeLogEntry(module, "returned", success, mail, message);
	end
end

--------------------------------------------
-- Deleted Mail Log

function module:logDeleted(success, mail, message)
	-- Log a deleted mail message.
	if (module.opt.logDeletedMail) then
		writeLogEntry(module, "deleted", success, mail, message);
	end
end

--------------------------------------------
-- Outgoing Mail Log

function module:logOutgoing(success, mail, message)
	-- Log an outgoing mail message.
	return writeLogEntry(module, "outgoing", success, mail, message);
end

--------------------------------------------
-- Mail Log UI

do
	local updateMailLog;
	local resizeMailLog;
	local resizingMailLog;
	local defaultLogWidth = 800;
	local function mailLogFrameSkeleton()
		local scrollChild = {
			-- "texture#tl#br:0:1#1:1:1:0.25"
--			"texture#s:40:20#l:5:0#i:icon",
			"font#s:50:20#l:5:0#i:icontext#v:GameFontNormal##1:1:1:l",
			"font#s:100:20#l:55:0#i:receiver#v:GameFontNormal##1:1:1:l",
			"font#s:100:20#l:160:0#i:sender#v:GameFontNormal##1:1:1:l",
			"font#s:200:20#l:265:0#i:subject#v:ChatFontNormal##1:1:1:l",
			"font#tl:55:0#br:-5:0#i:message#v:GameFontNormal##1:0:0:l",
			"font#tl:475:0#br:-5:0#i:comment#v:GameFontNormal##1:0:0:l",
			-- Having a moneyframe "here", but creating it dynamically later
			-- Having several icons "here", but creating them dynamically later
		}
		
		return "frame#n:CT_MailMod_MailLog#s:" .. defaultLogWidth .. ":500", {
			"backdrop#tooltip#0:0:0:0.75",
			"font#t:0:-10#v:GameFontNormalHuge#MAIL_LOG#1:1:1",
			
			"font#tl:60:-47#i:receiverHeading#v:GameFontNormalLarge#Receiver#1:1:1",
			"font#tl:165:-47#i:senderHeading#v:GameFontNormalLarge#Sender#1:1:1",
			"font#tl:270:-47#i:subjectHeading#v:GameFontNormalLarge#Subject#1:1:1",
			"font#tl:475:-47#i:moneyHeading#v:GameFontNormalLarge#Money#1:1:1",
			"font#tl:553:-47#i:itemsHeading#v:GameFontNormalLarge#Items#1:1:1",
			
			--"font#tl:20:-40#v:GameFontNormalLarge#Filter:#1:1:1",
			--"dropdown#n:CT_MAILMOD_MAILLOGDROPDOWN1#tl:80:-43#All Mail#Incoming Mail#Outgoing Mail",
			--"dropdown#n:CT_MAILMOD_MAILLOGDROPDOWN2#tl:220:-43#i:charDropdown#All Characters",
			
			
			
			["button#s:100:25#tr:-5:-5#v:GameMenuButtonTemplate#Close"] = {
				["onclick"] = function(self)
					HideUIPanel(CT_MailMod_MailLog);
				end
			},
			--"button#s:100:25#tr:-135:-38#v:GameMenuButtonTemplate#Reset Data",
			"texture#tl:5:-67#br:tr:-5:-69#1:0.82:0",
			
			["frame#tl:5:-72#br:-5:5#i:scrollChildren"] = {
				["frame#s:0:20#tl:0:0#r#i:1"] = scrollChild,
				["frame#s:0:20#tl:0:-20#r#i:2"] = scrollChild,
				["frame#s:0:20#tl:0:-40#r#i:3"] = scrollChild,
				["frame#s:0:20#tl:0:-60#r#i:4"] = scrollChild,
				["frame#s:0:20#tl:0:-80#r#i:5"] = scrollChild,
				["frame#s:0:20#tl:0:-100#r#i:6"] = scrollChild,
				["frame#s:0:20#tl:0:-120#r#i:7"] = scrollChild,
				["frame#s:0:20#tl:0:-140#r#i:8"] = scrollChild,
				["frame#s:0:20#tl:0:-160#r#i:9"] = scrollChild,
				["frame#s:0:20#tl:0:-180#r#i:10"] = scrollChild,
				["frame#s:0:20#tl:0:-200#r#i:11"] = scrollChild,
				["frame#s:0:20#tl:0:-220#r#i:12"] = scrollChild,
				["frame#s:0:20#tl:0:-240#r#i:13"] = scrollChild,
				["frame#s:0:20#tl:0:-260#r#i:14"] = scrollChild,
				["frame#s:0:20#tl:0:-280#r#i:15"] = scrollChild,
				["frame#s:0:20#tl:0:-300#r#i:16"] = scrollChild,
				["frame#s:0:20#tl:0:-320#r#i:17"] = scrollChild,
				["frame#s:0:20#tl:0:-340#r#i:18"] = scrollChild,
				["frame#s:0:20#tl:0:-360#r#i:19"] = scrollChild,
				["frame#s:0:20#tl:0:-380#r#i:20"] = scrollChild,
				["frame#s:0:20#tl:0:-400#r#i:21"] = scrollChild,
			},
			
			["onload"] = function(self)
				self:EnableMouse(true);
				module:registerMovable("MAILLOG", self, true);
				
				-- Scroll Frame
				local scrollFrame = CreateFrame("ScrollFrame", "CT_MailMod_MailLog_ScrollFrame",
					self, "FauxScrollFrameTemplate");
				scrollFrame:SetPoint("TOPLEFT", self, 5, -72);
				scrollFrame:SetPoint("BOTTOMRIGHT", self, -26, 5);
				scrollFrame:SetScript("OnVerticalScroll", function(self, offset, ...)
					FauxScrollFrame_OnVerticalScroll(self, offset, 20, updateMailLog);
				end);

				-- Resizing frames
				local onUpdate = function(self, elapsed, ...)
					if (resizingMailLog) then
						self.resizingTimer = self.resizingTimer + elapsed;
						if (self.resizingTimer > 0.1) then
							self.resizingTimer = 0;
							resizeMailLog(self:GetParent());
						end
					end
				end;
				local onEnter = function(self, ...)
					module:displayPredefinedTooltip(self, "RESIZE");
					self:SetScript("OnUpdate", onUpdate);
				end;
				local onLeave = function(self, ...)
					module:hideTooltip();
					self:SetScript("OnUpdate", nil);
				end;
				local onMouseDown = function(self, button, ...)
					if (button == "LeftButton") then
						resizingMailLog = true;
						self.resizingTimer = 0;
						self:GetParent():StartSizing(self.side);
					end
				end;
				local onMouseUp = function(self, button, ...)
					if (button == "LeftButton") then
						self:GetParent():StopMovingOrSizing();
						resizingMailLog = false;
						module:setOption("mailLogWidth", self:GetParent():GetWidth(), true);
					end
				end;

				self:SetResizable(true);
				self:SetMaxResize(UIParent:GetWidth(), 500);
				self:SetMinResize(defaultLogWidth - 100, 500);

				local rightFrame = CreateFrame("Frame", "CT_MailMod_MailLog_RightResizeFrame", self);
				rightFrame.side = "RIGHT";
				rightFrame.resizingTimer = 0;
				rightFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0);
				rightFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -5, 0);
				rightFrame:EnableMouse(true);
				rightFrame:SetScript("OnEnter", onEnter);
				rightFrame:SetScript("OnLeave", onLeave);
				rightFrame:SetScript("OnMouseDown", onMouseDown);
				rightFrame:SetScript("OnMouseUp", onMouseUp);

				local leftFrame = CreateFrame("Frame", "CT_MailMod_MailLog_LeftResizeFrame", self);
				leftFrame.side = "LEFT";
				leftFrame.resizingTimer = 0;
				leftFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
				leftFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 5, 0);
				leftFrame:EnableMouse(true);
				leftFrame:SetScript("OnEnter", onEnter);
				leftFrame:SetScript("OnLeave", onLeave);
				leftFrame:SetScript("OnMouseDown", onMouseDown);
				leftFrame:SetScript("OnMouseUp", onMouseUp);

				local width = module:getOption("mailLogWidth");
				self:SetWidth(width or defaultLogWidth);
				resizeMailLog(self);
			end,
			
			["onmousedown"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:moveMovable("MAILLOG");
				end
			end,
			
			["onmouseup"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:stopMovable("MAILLOG");
				elseif ( button == "RightButton" ) then
					module:resetMovable("MAILLOG");
					self:ClearAllPoints();
					self:SetPoint("CENTER", UIParent);
				end
			end,
			
			["onenter"] = function(self)
				module:displayPredefinedTooltip(self, "DRAG");
			end,
			
			["onleave"] = function(self)
				module:hideTooltip();
			end
		};
	end
	
	local updateMailEntry, mailLogFrame;
	
	do
		local createMoneyFrame;
		do
			local moneyTypeInfo = {
				UpdateFunc = function(self)
					return self.staticMoney;
				end,
				collapse = 1,
				truncateSmallCoins = 1,
			};

			createMoneyFrame = function(parent, id) -- Local
				local frameName = "CT_MailMod_MailLogMoneyFrame"..id;
				local frame = CreateFrame("Frame", frameName, parent, "SmallMoneyFrameTemplate");
				
				_G[frameName.."GoldButton"]:EnableMouse(false);
				_G[frameName.."SilverButton"]:EnableMouse(false);
				_G[frameName.."CopperButton"]:EnableMouse(false);
				
				local diff = mailLogFrame:GetWidth() - defaultLogWidth;
				frame:SetPoint("LEFT", parent, "LEFT", 470 + diff, 0);
				frame.moneyType = "STATIC";
				frame.hasPickup = 0;
				frame.info = moneyTypeInfo
				return frame;
			end
		end
		
		local createItemFrame;
		do
			local function itemOnEnter(self, ...)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
				GameTooltip:SetHyperlink(self.link);
				GameTooltip:AddLine(("Item Count: \124cffffffff%d\r"):format(self.count), 1, 0.82, 0);
				GameTooltip:Show();
			end

			local function itemOnLeave(self, ...)
				GameTooltip:Hide();
			end

			createItemFrame = function(parent, id) -- Local
				local diff = mailLogFrame:GetWidth() - defaultLogWidth;
				local button = CreateFrame("Button", nil, parent);
				button:SetWidth(16);
				button:SetHeight(16);
				button:SetPoint("LEFT", parent, "LEFT", 530 + diff + id * 18, 0);
				button:SetScript("OnEnter", itemOnEnter);
				button:SetScript("OnLeave", itemOnLeave);
				return button;
			end
		end
		
		local function formatPlayer(name)
			if ( name == module:getPlayerName() ) then
				name = "\124cff888888Me\124r";
			elseif ( module:nameIsPlayer(name) ) then
				name = ("\124cffffd100%s\124r"):format(module:filterName(name));
			else
				name = module:filterName(name);
			end
			return name;
		end
		
		updateMailEntry = function(frame, i, success, type, message, receiver, sender, subject, money, timestamp, ...) -- Local
			local moneyFrame = frame.moneyFrame;
			local items = select('#', ...);
			
			frame.timestamp = timestamp;

			if ( success ) then
				-- Success
				
				receiver = formatPlayer(receiver);
				sender = formatPlayer(sender);
				
				frame.receiver:SetText(receiver);
				frame.sender:SetText(sender);
				frame.subject:SetText(subject);
				frame.message:SetText("");
				frame.comment:SetText("");
			else
				-- Failure
				money = 0;

				local diff = mailLogFrame:GetWidth() - defaultLogWidth;
				frame.comment:ClearAllPoints();
				frame.comment:SetPoint("TOPLEFT", frame, "TOPLEFT", 470 + diff, 0);
				frame.comment:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 0);

				if (receiver) then
					receiver = formatPlayer(receiver);
					sender = formatPlayer(sender);

					frame.receiver:SetText(receiver);
					frame.sender:SetText(sender);
					frame.subject:SetText(subject);
					frame.message:SetText("");
					frame.comment:SetText(message);
				else
					frame.receiver:SetText("");
					frame.sender:SetText("");
					frame.subject:SetText("");
					frame.message:SetText(message);
					frame.comment:SetText("");
				end
			end
			
			-- Icon
--			frame.icon:SetTexture("Interface\\AddOns\\CT_MailMod\\Images\\mail_"..type);
			if (type == "returned") then
				frame.icontext:SetText("Return");
			elseif (type == "deleted") then
				frame.icontext:SetText("Delete");
			elseif (type == "outgoing") then
				frame.icontext:SetText("Send");
			elseif (type == "incoming") then
				frame.icontext:SetText("Open");
			else
				frame.icontext:SetText("");
			end

			-- Handling money
			if ( money > 0 ) then  -- Money taken
				if ( not moneyFrame ) then
					moneyFrame = createMoneyFrame(frame, i);
					frame.moneyFrame = moneyFrame;
				end
				SetMoneyFrameColor(moneyFrame:GetName(), "white");
				moneyFrame:Show();
				MoneyFrame_Update(moneyFrame:GetName(), money);
			elseif ( money < 0 ) then  -- COD
				if ( not moneyFrame ) then
					moneyFrame = createMoneyFrame(frame, i);
					frame.moneyFrame = moneyFrame;
				end
				SetMoneyFrameColor(moneyFrame:GetName(), "red");
				moneyFrame:Show();
				MoneyFrame_Update(moneyFrame:GetName(), -money);
			elseif ( moneyFrame ) then
				MoneyFrame_Update(moneyFrame:GetName(), 0);
				moneyFrame:Hide();
			end
			
			-- Handling items
			if (not frame.items) then
				frame.items = {};
			end
			for y = 1, module.MAX_ATTACHMENTS, 1 do
				item = frame.items[y];
				if ( y <= items ) then
					if ( not item ) then
						item = createItemFrame(frame, y);
						frame.items[y] = item;
					end
					local link, count = (select(y, ...));
					link, count = link:match("^([^/]+)/(.+)$");
					if ( link and count ) then
						item:SetNormalTexture(select(10, GetItemInfo(link)) or "Interface\\Icons\\INV_Misc_QuestionMark");
						item.link = link;
						item.count = count;
						item:Show();
					else
						item:Hide();
					end
				elseif ( item ) then
					item:Hide();
				end
			end
		end
	end

	resizeMailLog = function(logFrame)
		local tostring = tostring;
		local diff = logFrame:GetWidth() - defaultLogWidth;
		local subjectWidth = 200 + diff;
		local children = logFrame.scrollChildren;

		logFrame.moneyHeading:ClearAllPoints();
		logFrame.moneyHeading:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 475 + diff, -47);

		logFrame.itemsHeading:ClearAllPoints();
		logFrame.itemsHeading:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 553 + diff, -47);

		for i = 1, 21 do
			local frame = children[tostring(i)];
			frame.subject:SetWidth(subjectWidth);
			if (frame.moneyFrame) then
				frame.moneyFrame:ClearAllPoints();
				frame.moneyFrame:SetPoint("LEFT", frame, "LEFT", 470 + diff, 0);
			end
			if (frame.items) then
				for id, item in ipairs(frame.items) do
					item:ClearAllPoints();
					item:SetPoint("LEFT", frame, "LEFT", (530 + diff) + id * 18, 0);
				end
			end
			frame.comment:ClearAllPoints();
			frame.comment:SetPoint("TOPLEFT", frame, "TOPLEFT", 470 + diff, 0);
			frame.comment:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 0);
		end
	end

	updateMailLog = function()
		FauxScrollFrame_Update(CT_MailMod_MailLog_ScrollFrame, #getLogTable(), 21, 20);
		local offset = FauxScrollFrame_GetOffset(CT_MailMod_MailLog_ScrollFrame);
		local tostring, children, frame = tostring, mailLogFrame.scrollChildren;
		
		for i = 1, 21, 1 do
			frame = children[tostring(i)];
			local entry = getLogEntry(i+offset);
			if ( entry ) then
				frame:Show();
				updateMailEntry(frame, i, decodeLogEntry(entry));
			else
				frame:Hide();
			end
		end
	end

	function module:updateMailLog()
		if (CT_MailMod_MailLog and CT_MailMod_MailLog:IsShown()) then
			updateMailLog();
		end
	end
	
	local function showMailLog()
		if ( not mailLogFrame ) then
			mailLogFrame = module:getFrame(mailLogFrameSkeleton);
		end
		module:scaleMailLog();
		tinsert(UISpecialFrames, "CT_MailMod_MailLog");
		ShowUIPanel(CT_MailMod_MailLog);
		updateMailLog();
	end

	local function toggleMailLog()
		if ( not mailLogFrame ) then
			showMailLog();
		else
			if (mailLogFrame:IsShown()) then
				HideUIPanel(mailLogFrame);
			else
				showMailLog();
			end
		end
	end
	
	function module:scaleMailLog()
		if (mailLogFrame) then
			mailLogFrame:SetScale(module.opt.logWindowScale);
		end
	end

	module:setSlashCmd(toggleMailLog, "/maillog");
	module.showMailLog = showMailLog;
	module.toggleMailLog = toggleMailLog;
end
