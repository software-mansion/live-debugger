import {
  Accordion as BaseAccordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

interface RoadmapAccordionProps {
  data: {
    versionNumber: string;
    bulletpoints: string[];
  }[];
}

const itemContent = (bulletpoints: string[]) => (
  <ul className="w-full list-disc space-y-2 py-1.5 pl-7">
    {bulletpoints.map((point, index) => (
      <li key={index} className="text-secondary-strong text-sm font-normal">
        {point}
      </li>
    ))}
  </ul>
);

export function Accordion({ data }: RoadmapAccordionProps) {
  return (
    <BaseAccordion type="single" defaultValue={`item-0`} className="w-full">
      {data.map((item, i) => {
        return (
          <AccordionItem value={`item-${i.toFixed()}`} key={item.versionNumber}>
            <AccordionTrigger>
              <div className="flex w-full flex-col gap-4 md:flex-row md:items-start md:gap-6">
                <div className="flex w-full flex-row items-start gap-6">
                  <div className="w-8 shrink-0 text-left font-medium sm:w-16 md:w-24 lg:w-42">
                    {String(i + 1).padStart(2, "0")}
                  </div>
                  <p className="text-left font-medium md:w-64 lg:w-100">
                    Release&nbsp;{item.versionNumber}
                  </p>
                </div>
                <AccordionContent>
                  {itemContent(item.bulletpoints)}
                </AccordionContent>
              </div>
            </AccordionTrigger>
          </AccordionItem>
        );
      })}
    </BaseAccordion>
  );
}
