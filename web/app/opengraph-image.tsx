import { ImageResponse } from "next/og";

export const alt = "Commandment: voice to text for macOS";
export const size = { height: 630, width: 1200 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    <div
      style={{
        backgroundColor: "#1c1c1e",
        display: "flex",
        flexDirection: "column",
        height: "100%",
        justifyContent: "center",
        padding: "100px",
        width: "100%",
      }}
    >
      <div
        style={{
          color: "#f5f5f7",
          fontSize: 88,
          fontWeight: 700,
          letterSpacing: "-0.04em",
        }}
      >
        Commandment
      </div>
      <div style={{ color: "#c5c5ca", fontSize: 44, marginTop: 16 }}>
        Voice to text, instantly.
      </div>
      <div style={{ color: "#98989d", fontSize: 30, marginTop: 28 }}>
        A macOS menu bar dictation app.
      </div>
    </div>,
    { ...size }
  );
}
