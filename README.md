
<h1 align="center">
ObjectCache
<div align="center">A robust, blazing fast part cache for Roblox</div>

## Introduction
ObjectCache is a modern implementation on handling thousands of active parts, while keeping performance high.

## Why ObjectCache?
The source code is minimal and with no bloat, and with an important difference - it uses Roblox's `BulkMoveTo` API to achieve peak performance. Instead of manually setting the CFrame of each part one-by-one, all parts are batched together. And best of all, you don't need to worry about any of this! ObjectCache puts all returned objects into a queue to move them away, in the same frame as you call the method.

## API
The API is dead simple - easy to learn, and eventually forget.
ObjectCache is fully typed, but an API reference is always handy to have:
```luau
ObjectCacheConstructor.new(Template: BasePart, CacheSize: number?, CachesContainer: Folder?) -> ObjectCache

ObjectCache:GetPart(PartCFrame: CFrame?): BasePart

ObjectCache:ReturnPart(Part: BasePart)

ObjectCache:Destroy()
```
You may have noticed that `ObjectCache:GetPart` lets you provide an optional target CFrame. This argument lets you squeeze out the maximum performance out of the module! Since `:GetPart(TargetCFrame)` and `:ReturnPart(Object)` both use queued `workspace:BulkMoveTo` calls, it can actually be more performant to call these two methods every frame.
The following video calls :GetPart and :ReturnPart every frame, yet runs smooth as butter:

*The place file used in the above video* (*can be found here*)[]

# Installation

Simply grab the file from Roblox marketplace: https://create.roblox.com/store/asset/18819618773/ObjectCache
