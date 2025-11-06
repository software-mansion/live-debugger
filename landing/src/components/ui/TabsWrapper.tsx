import { useRef, useState, useEffect } from "react";
import {
  Tabs as BaseTabs,
  TabsList,
  TabsTrigger,
  TabsContent,
} from "@/components/ui/tabs";

interface TabData {
  key: string;
  title: string;
}

interface TabsProps {
  tabData: TabData[];
  [slotKey: string]: any;
}

export function Tabs({ tabData, ...slots }: TabsProps) {
  const defaultValue = tabData.length > 0 ? tabData[0].key : undefined;

  const [maxHeight, setMaxHeight] = useState<number | "auto">("auto");
  const contentRefs = useRef<Record<string, HTMLDivElement | null>>({});

  useEffect(() => {
    if (tabData.length > 0) {
      const currentRefs = Object.values(contentRefs.current).filter(
        Boolean,
      ) as HTMLDivElement[];

      if (currentRefs.length > 0) {
        const tallestHeight = Math.max(
          ...currentRefs.map((el) => el.scrollHeight),
        );

        if (tallestHeight > 0) {
          setMaxHeight(tallestHeight);
        }
      }
    }
  }, [tabData]);

  return (
    <BaseTabs defaultValue={defaultValue} className="w-full">
      <TabsList>
        {tabData.map((tab) => (
          <TabsTrigger value={tab.key} key={tab.key}>
            {tab.title}
          </TabsTrigger>
        ))}
      </TabsList>

      <div
        style={{
          minHeight: typeof maxHeight === "number" ? `${maxHeight}px` : "auto",
        }}
        className="relative w-full"
      >
        {tabData.map((tab) => (
          <TabsContent
            ref={(el) => {
              contentRefs.current[tab.key] = el;
            }}
            value={tab.key}
            key={`${tab.key}-content`}
            className="absolute top-0 w-full data-[state=inactive]:hidden"
          >
            {slots[tab.key]}
          </TabsContent>
        ))}
      </div>
    </BaseTabs>
  );
}
