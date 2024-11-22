--
-- Config
--

local width = 640
local ratio = display.pixelHeight/display.pixelWidth
if ratio < 1.5 then -- Below 1.5 are tablets(iPad + Android tablet)
	width = 720
end
local height = width * ratio
application =
{
	content =
	{
		width = width,
        height = height,
		scale = "letterbox",
	},
}
