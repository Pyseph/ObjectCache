interface ObjectCache<T extends BasePart> {
	GetPart(partCFrame?: CFrame): T;
	ReturnPart(part: T): void;

	IsInUse(part: T): boolean;

	ExpandCache(amount: number): void;
	SetExpandAmount(amount: number): void;

	Update(): void;
}
declare const ObjectCache: new <T extends BasePart>(template: T, cacheSize?: number, cachesContainer?: Folder) => ObjectCache<T>;
export = ObjectCache;

