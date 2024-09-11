declare namespace ObjectCacheConstructor {
  interface Constructor<T extends BasePart> {
    new (): ObjectCache<T>;
  }
}

interface ObjectCache<T extends BasePart> {
  GetPart(partCFrame?: CFrame): T;
  ReturnPart(part: T): void;

  IsInUse(part: T): boolean;

  ExpandCache(amount: number): void;
  SetExpandAmount(amount: number): void;

  Update(): void;
}
