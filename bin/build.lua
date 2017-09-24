-- =============================================================
-- >> MODULE IMPORTS
-- =============================================================

-- Lua imports
local string = require("string")

-- Luvit imports
local fs = require("fs")

-- Lit imports
local base64	= require("base64")
local path		= require("path")
local sh		= require("sh")

-- =============================================================
-- >> UTILITY VARIABLES
-- =============================================================

DIRECTORY_BUILD			= "build"			-- Directory for outputting transpiled/packed Lua
DIRECTORY_MOONSCRIPT	= "src/moonscript"	-- Directory for Moonscript source files

PATTERN_DIRECTIVE	= "(@include{[%w/%.]+})"	-- Extracts file directives
PATTERN_FILE		= "@include{(.*)}"			-- Extracts file paths

-- =============================================================
-- >> UTILITY FUNCTIONS
-- =============================================================

local function execute(command, stdin)
	executed = sh.command(command)({
		__input		= stdin,
		__exitcode	= 0,
		__signal	= 0
	})

	return tostring(executed), executed.__exitcode == 0
end

local function transpile(file)
	local contents	= fs.readFileSync(file)
	contents		= execute("moonc --", contents)
	contents		= string.gsub(contents, PATTERN_DIRECTIVE, function (directive)
		return string.gsub(directive, PATTERN_FILE, function (file)
			local minified = execute("minify --js", fs.readFileSync(file))
			--local minified = fs.readFileSync(file)
			return base64.encode(minified, #minified)
		end)
	end)

	return execute("luamin -c", contents)
	--return contents
end

local function is_valid_directory(directory)
	return fs.existsSync(directory) and fs.lstatSync(directory).type == "directory"
end

-- =============================================================
-- >> MODULE BLOCK
-- =============================================================

if not is_valid_directory(DIRECTORY_BUILD) then
	fs.mkdirSync(DIRECTORY_BUILD)
end

files = fs.readdirSync(DIRECTORY_MOONSCRIPT)
for _, file in ipairs(files) do
	print("Building '"..file.."'...")
	transpiled	= transpile(path.join(DIRECTORY_MOONSCRIPT, file))
	name		= file:sub(0, -6)..".lua" -- Turn .moon into .lua
	fs.writeFileSync(path.join(DIRECTORY_BUILD, name), transpiled)
end

print("Build finished!")