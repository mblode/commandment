export const JsonLd = ({ data }: { data: Record<string, unknown> }) => (
  <script
    // biome-ignore lint/security/noDangerouslySetInnerHtml: JSON.stringify of a static schema object is safe.
    dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    type="application/ld+json"
  />
);
