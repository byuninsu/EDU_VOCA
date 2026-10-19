"""Check all 64-bit native APK libraries for 16 KB ELF and ZIP alignment."""
import argparse
import json
import struct
import zipfile

def relro_overlaps_writable(address, size, segments):
    """Check whether page rounding protects writable bytes outside RELRO.

    Android's linker rounds the protection range to page boundaries. A RELRO
    end inside page padding is safe; a writable LOAD tail in that page is not.
    """
    end = address + size
    padding = ((address // 16384 * 16384, address),
               (end, (end + 16383) // 16384 * 16384))
    return any(
        segment["writable"] and max(start, segment["address"]) <
        min(stop, segment["address"] + segment["memory_size"])
        for start, stop in padding for segment in segments
    )

def inspect(apk):
    results = []
    with open(apk, "rb") as raw, zipfile.ZipFile(apk) as archive:
        for entry in archive.infolist():
            if not entry.filename.endswith(".so"):
                continue
            if not entry.filename.startswith(("lib/arm64-v8a/", "lib/x86_64/")):
                continue
            data = archive.read(entry)
            if data[:4] != b"\x7fELF" or data[4] != 2:
                raise ValueError("Expected ELF64: " + entry.filename)
            endian = "<" if data[5] == 1 else ">"
            phoff = struct.unpack_from(endian + "Q", data, 32)[0]
            phsize, count = struct.unpack_from(endian + "HH", data, 54)
            segments = []
            relro_segments = []
            for index in range(count):
                values = struct.unpack_from(endian + "IIQQQQQQ", data, phoff + index * phsize)
                kind, flags, offset, address, _, _, memory_size, alignment = values
                if kind == 1:
                    segments.append({
                        "alignment": alignment,
                        "offset": offset,
                        "address": address,
                        "memory_size": memory_size,
                        "writable": bool(flags & 2),
                        "pass": alignment >= 16384 and offset % 16384 == address % 16384,
                    })
                elif kind == 0x6474E552:  # PT_GNU_RELRO
                    relro_segments.append({
                        "address": address,
                        "memory_size": memory_size,
                        "end_aligned": (address + memory_size) % 16384 == 0,
                    })
            for relro in relro_segments:
                relro["writable_overlap"] = relro_overlaps_writable(
                    relro["address"], relro["memory_size"], segments)
                relro["pass"] = not relro["writable_overlap"]
            raw.seek(entry.header_offset + 26)
            name_length, extra_length = struct.unpack("<HH", raw.read(4))
            data_offset = entry.header_offset + 30 + name_length + extra_length
            zip_ok = entry.compress_type != zipfile.ZIP_STORED or data_offset % 16384 == 0
            results.append({
                "library": entry.filename,
                "segments": segments,
                "relro_segments": relro_segments,
                "relro_pass": all(s["pass"] for s in relro_segments),
                "zip_offset": data_offset,
                "zip_pass": zip_ok,
                "pass": (bool(segments) and all(s["pass"] for s in segments)
                         and all(s["pass"] for s in relro_segments) and zip_ok),
            })
    return {"apk": str(apk), "pass": bool(results) and all(r["pass"] for r in results), "libraries": results}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("apk")
    parser.add_argument("--output")
    args = parser.parse_args()
    result = inspect(args.apk)
    output = json.dumps(result, indent=2)
    print(output)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(output + "\n")
    raise SystemExit(0 if result["pass"] else 1)
