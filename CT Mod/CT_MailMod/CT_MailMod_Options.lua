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
-- Options Window

local optionsFrameList;

local function optionsInit()
	optionsFrameList = {};

	-- Dummy frame representing a master frame.
	local frame = {};
	frame.offset = 0;
	frame.size = 0;
	frame.details = "";
	frame.yoffset = 0;
	frame.top = 0;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsGetData()
	local frame = optionsFrameList[#optionsFrameList];
	return frame.data;
end

local function optionsAddFrame(offset, size, details)
	local yoffset;
	local prevFrame = optionsFrameList[#optionsFrameList];
	if (prevFrame) then
		yoffset = prevFrame.yoffset;
	else
		yoffset = 0;
	end
	yoffset = yoffset + offset;

	local frame = {};
	frame.offset = offset;
	frame.size = size;
	frame.details = details;
	frame.yoffset = 0;
	frame.top = yoffset;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsAddObject(offset, size, details)
	local frame = optionsFrameList[#optionsFrameList];
	local yoffset = frame.yoffset + offset;

	details = gsub(details, "%%y", yoffset);
	details = gsub(details, "%%s", size);
	tinsert(frame.data, details);

	frame.yoffset = yoffset - size;
end

local function optionsAddScript(name, func)
	local frame = optionsFrameList[#optionsFrameList];
	frame.data[name] = func;
end

local function optionsEndFrame()
	local frame = tremove(optionsFrameList);

	local size = frame.size;
	local top = frame.top;
	local bot;
	if (size == 0) then
		bot = top + frame.yoffset;
	else
		bot = top - size;
	end

	local details = frame.details;

	details = gsub(details, "%%y", top);
	details = gsub(details, "%%b", bot);
	details = gsub(details, "%%s", size);

	local prevFrame = optionsFrameList[#optionsFrameList];
	prevFrame.yoffset = bot;
	prevFrame.data[details] = frame.data;
end

module.frame = function()
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";

	optionsInit();

	optionsAddFrame(-5, 0, "frame#tl:0:%y#r");
	-- Tips
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctmail, /ctmm, or /ctmailmod to open this options window directly.#" .. textColor2 .. ":l");

	-- General Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#General");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockTrades#Block trades while using mailbox");
		optionsAddObject( -3,   26, "checkbutton#tl:10:%y#o:openAllBags#Open all bags when mailbox opens");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:closeAllBags#Close all bags when mailbox closes");
		optionsAddObject( -3,   26, "checkbutton#tl:10:%y#o:showMoneyChange#Show net income when the mailbox closes");

	-- Inbox Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Inbox");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:inboxMouseWheel:true#Enable mouse wheel scrolling");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowNumbers:true#Show message numbers");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowLong:true#Show long subjects on two lines");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowExpiry:true#Show message expiry buttons");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowInbox:true#Show number of messages in the inbox");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowMailbox:true#Show number of messages not in the inbox");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolMultipleItems:true#Show all attachments in message tooltips");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolSelectMsg:true#Show tooltip for message checkboxes");
		optionsAddObject(-10, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Right-click the Prev/Next buttons to jump to the first/last page of the inbox.#" .. textColor1 .. ":l");

	-- Selecting Messages
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Message Selection");
		optionsAddObject(-10, 4*13, "font#t:0:%y#s:0:%s#l:13:0#r#Selecting messages will add them to the selection list.  Unselecting messages will remove them from the selection list.#" .. textColor3 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:10:%y#o:inboxSenderNew:true#Clear selection list before selecting a sender");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxRangeNew:true#Clear selection list before selecting a range");
		optionsAddObject(-10, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select or unselect a message, click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select messages with similar subjects, Alt left-click the message's checkbox.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect messages with similar subjects, Alt right-click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select all messages from the same sender, Ctrl left-click the message's checkbox.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect all messages from the same sender, Ctrl right-click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select a range of messages, Shift click one message's checkbox and then Shift left-click a second one.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect a range of messages, Shift click one message's checkbox and then Shift right-click a second one.#" .. textColor1 .. ":l");

	-- Mail Log Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Mail Log");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:printLog#Print log messages to chat");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:saveLog:true#Save log messages in the mail log");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logOpenedMail:true#Log opened mail");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logReturnedMail:true#Log returned mail");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logDeletedMail:true#Log deleted mail");
		optionsAddObject(-15,   17, "slider#t:0:%y#o:logWindowScale:1#s:175:%s#Mail Log Scale - <value>#0.20:2:0.01");
		optionsAddObject(-15, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Type /maillog to open the mail log when you are not at a mailbox.#" .. textColor1 .. ":l");

	-- Send Mail Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Send Mail");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAltClickItem#Alt left-click adds items to the Send Mail tab");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:sendmailMoneySubject:true#Replace blank subject with money amount");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAutoCompleteUse#Configure auto-completion of Send To name");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:sendmailAutoCompleteFriends#Friends list");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:sendmailAutoCompleteGuild#Guild members");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:sendmailAutoCompleteGroup#Group members (party or raid)");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:sendmailAutoCompleteInteracted#Players interacted with (whispers, etc)");
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

local function getoption(name, default)
	local value;
	value = module:getOption(name);
	if (value == nil) then
		return default;
	else
		return value;
	end
end

module.opt = {};

module.update = function(self, type, value)
	local opt = module.opt;
	if (type == "init") then
		-- General
		opt.openAllBags = getoption("openAllBags", false);
		opt.closeAllBags = getoption("closeAllBags", false);
		opt.blockTrades = getoption("blockTrades", false);
		opt.showMoneyChange = getoption("showMoneyChange", false);

		-- Inbox
		opt.inboxMouseWheel = getoption("inboxMouseWheel", true);
		opt.inboxShowNumbers = getoption("inboxShowNumbers", true);
		opt.inboxShowLong = getoption("inboxShowLong", true);
		opt.inboxShowExpiry = getoption("inboxShowExpiry", true);
		opt.inboxShowInbox = getoption("inboxShowInbox", true);
		opt.inboxShowMailbox = getoption("inboxShowMailbox", true);
		opt.toolMultipleItems = getoption("toolMultipleItems", true);
		opt.toolSelectMsg = getoption("toolSelectMsg", true);

		-- Message selection
		opt.inboxSenderNew = getoption("inboxSenderNew", true);
		opt.inboxRangeNew = getoption("inboxRangeNew", true);

		-- Mail Log
		opt.printLog = getoption("printLog", false);
		opt.saveLog = getoption("saveLog", true);
		opt.logOpenedMail = getoption("logOpenedMail", true);
		opt.logReturnedMail = getoption("logReturnedMail", true);
		opt.logDeletedMail = getoption("logDeletedMail", true);
		opt.logWindowScale = getoption("logWindowScale", 1);

		-- Send Mail
		opt.sendmailAltClickItem = getoption("sendmailAltClickItem", true);
		opt.sendmailMoneySubject = getoption("sendmailMoneySubject", true);
		module.configureSendToNameAutoComplete();

	-- General options
	else
		opt[type] = value;
		if (
			type == "inboxShowNumbers" or
			type == "inboxShowLong" or
			type == "inboxShowExpiry" or
			type == "inboxShowInbox" or
			type == "inboxShowMailbox"
		) then
			module:raiseCustomEvent("INCOMING_UPDATE");

		elseif (type == "logWindowScale") then
			module:scaleMailLog();

		elseif (type == "blockTrades") then
			module.configureBlockTradesMail(value);

		elseif (
			type == "sendmailAutoCompleteUse" or
			type == "sendmailAutoCompleteFriends" or
			type == "sendmailAutoCompleteGuild" or
			type == "sendmailAutoCompleteInteracted" or
			type == "sendmailAutoCompleteGroup"
		) then
			module.configureSendToNameAutoComplete();
		end
	end
end
