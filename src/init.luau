--!strict
--!optimize 2
--!native
local FAR_AWAY_CFRAME = CFrame.new(9e9, 0, 9e9)
local EXPAND_BY_AMOUNT = 50

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

function Cache:_GetNew(Amount: number, Warn: boolean)
	if Warn then
		warn(`ObjectCache: Cache retrieval exceeded preallocated amount! expanding by {Amount}...`)
	end

	local FreeObjectsContainer = self._FreeObjects
	local InitialLength = #self._FreeObjects
	for Index = InitialLength + 1, InitialLength + Amount do
		local Object = self._Template:Clone()
		Object:PivotTo(FAR_AWAY_CFRAME)
		FreeObjectsContainer[Index] = Object
		Object.Parent = self.CacheHolder
	end

	return FreeObjectsContainer[InitialLength + Amount]
end

function Cache:GetPart(PartCFrame: CFrame?): BasePart
	local Object = table.remove(self._FreeObjects) or self:_GetNew(self._ExpandAmount, true)
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

function Cache:Update()
	task.spawn(UpdateMovementThread)
end

function Cache:ExpandCache(Amount: number)
	assert(typeof(Amount) ~= "number" or Amount >= 0, `Invalid argument #1 to 'ObjectCache:ExpandCache' (positive number expected, got {typeof(Amount)})`)
	self:_GetNew(Amount, false)
end
function Cache:SetExpandAmount(Amount: number)
	assert(typeof(Amount) ~= "number" or Amount > 0, `Invalid argument #1 to 'ObjectCache:SetExpandAmount' (positive number expected, got {typeof(Amount)})`)
	self._ExpandAmount = Amount
end

function Cache:IsInUse(Object: BasePart): boolean
	return self._Objects[Object] ~= nil
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
	local TargetCFrame = FAR_AWAY_CFRAME
	local TargetParts = table.create(PreallocAmount)
	local TargetCFrames = table.create(PreallocAmount)
	for Index = 1, PreallocAmount do
		local Object = Template:Clone()
		FreeObjects[Index] = Object
		TargetParts[Index] = Object
		TargetCFrames[Index] = TargetCFrame
	end

	workspace:BulkMoveTo(TargetParts, TargetCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	for Index = 1, PreallocAmount do
		FreeObjects[Index].Parent = CacheParent
	end

	return setmetatable({
		CacheHolder = CacheParent,
		_ExpandAmount = EXPAND_BY_AMOUNT,
		_Template = Template,
		_FreeObjects = FreeObjects,
		_Objects = Objects,
		_PreallocatedAmount = PreallocAmount,
	}, Cache)
end

return Constructor