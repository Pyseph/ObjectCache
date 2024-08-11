--!strict
--!optimize 2
--!native
local FAR_AWAY_CFRAME = CFrame.new(9e9, 0, 9e9)

local MovingParts = table.create(10_000)
local MovingCFrames = table.create(10_000)

local ScheduledUpdate = false
local function UpdateMovement()
	while true do
		workspace:BulkMoveTo(MovingParts, MovingCFrames, Enum.BulkMoveMode.FireCFrameChanged)

		table.clear(MovingParts)
		table.clear(MovingCFrames)

		ScheduledUpdate = false
		coroutine.yield()
	end
end
local UpdateMovementThread = coroutine.create(UpdateMovement)

local Cache = {}
Cache.__index = Cache

function Cache:_GetNew()
	warn("ObjectCache: Cache retrieval exceeded preallocated amount! cloning a new part...")
	local Object = self._Template:Clone()
	Object:PivotTo(FAR_AWAY_CFRAME)
	Object.Parent = self.CacheHolder

	return Object
end

function Cache:GetPart(PartCFrame: CFrame?): BasePart
	local Object = table.remove(self._FreeObjects) or self:_GetNew()
	self._Objects[Object] = nil
	if PartCFrame then
		table.insert(MovingParts, Object)
		table.insert(MovingCFrames, PartCFrame)

		if not ScheduledUpdate then
			ScheduledUpdate = true
			task.defer(UpdateMovementThread)
		end
	end

	return Object
end
function Cache:ReturnPart(Part: BasePart)
	if self._Objects[Part] then
		return
	end

	self._Objects[Part] = true

	table.insert(self._FreeObjects, Part)
	table.insert(MovingParts, Part)
	table.insert(MovingCFrames, FAR_AWAY_CFRAME)

	if not ScheduledUpdate then
		ScheduledUpdate = true
		task.defer(UpdateMovementThread)
	end
end

function Cache:Destroy()
	self.CacheHolder:Destroy()
end

local function GetCacheContainer(CachesContainer)
	local CacheHolder = Instance.new("Folder")
	CacheHolder.Name = "ObjectCache"
	CacheHolder.Parent = CachesContainer

	return CacheHolder
end

local Constructor = {}
function Constructor.new(Template: BasePart, CacheSize: number?, CachesContainer: Instance?)
	local TemplateType = typeof(Template)
	assert(TemplateType == "Instance", `Invalid argument #1 to 'ObjectCache.new' (BasePart expected, got {TemplateType})`)

	assert(Template:IsA("BasePart"), `Invalid argument #1 to 'ObjectCache.new' (BasePart expected, got {Template.ClassName})`)
	assert(Template.Archivable, `ObjectCache: Cannot use template part provided, as it has Archivable set to false.`)

	local CacheSizeType = typeof(CacheSize)
	assert(CacheSize == nil or CacheSizeType == "number", `Invalid argument #2 to 'ObjectCache.new' (number expected, got {CacheSizeType})`)
	assert(CacheSize == nil or CacheSize >= 0, `Invalid argument #2 to 'ObjectCache.new' (positive number expected, got {CacheSize})`)

	local ContainerType = typeof(CachesContainer)
	assert(CachesContainer == nil or ContainerType == "Instance", `Invalid argument #3 to 'ObjectCache.new' (Instance expected, got {ContainerType})`)

	local PreallocAmount = CacheSize or 10
	local CacheParent = GetCacheContainer(CachesContainer or workspace)

	local Objects = table.create(PreallocAmount)
	local FreeObjects = table.create(PreallocAmount)

	Template.Anchored = true
	for Index = 1, PreallocAmount do
		local Object = Template:Clone()
		FreeObjects[Index] = Object
		MovingParts[Index] = Object
		MovingCFrames[Index] = FAR_AWAY_CFRAME
	end

	workspace:BulkMoveTo(MovingParts, MovingCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	for Index = 1, PreallocAmount do
		FreeObjects[Index].Parent = CacheParent
	end

	return setmetatable({
		CacheHolder = CacheParent,
		_Template = Template,
		_FreeObjects = FreeObjects,
		_Objects = Objects,
	}, Cache)
end

return Constructor