// Cloudflare Worker：幫「活動雷達」代抓網頁內容，回傳 JSON。
// 用法：GET https://你的-worker網址/?url=https://example.com/event
export default {
  async fetch(request) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Content-Type": "application/json; charset=utf-8",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });

    const target = new URL(request.url).searchParams.get("url") || "";
    let u;
    try { u = new URL(target); } catch { return json({ error: "網址格式不正確" }, 400); }
    if (!/^https?:$/.test(u.protocol)) return json({ error: "只支援 http/https" }, 400);
    // 擋掉內網與本機位址，避免被拿來探測內部服務
    const h = u.hostname;
    if (/^(localhost|0\.0\.0\.0|127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.)/.test(h) || h.endsWith(".local") || h.includes(":")) {
      return json({ error: "不允許的網址" }, 400);
    }

    let res;
    try {
      res = await fetch(u.toString(), {
        redirect: "follow",
        headers: {
          // 社群平台對一般連結預覽爬蟲通常會回傳 og: 標籤
          "User-Agent": "Mozilla/5.0 (compatible; facebookexternalhit/1.1; +http://www.facebook.com/externalhit_uatext.php)",
          "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.5",
        },
      });
    } catch { return json({ error: "無法連線到該網址" }, 502); }
    if (!res.ok) return json({ error: "對方網站回應 " + res.status }, 502);

    const html = (await res.text()).slice(0, 1500000);
    const meta = (n) => {
      const m = html.match(new RegExp('<meta[^>]+(?:property|name)=["\']' + n + '["\'][^>]*content=["\']([^"\']*)["\']', "i"))
        || html.match(new RegExp('<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']' + n + '["\']', "i"));
      return m ? decode(m[1]) : "";
    };
    const t = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
    const text = decode(
      html.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>|<[^>]+>/g, " ")
    ).replace(/\s+/g, " ").slice(0, 2500);

    // 若網頁有 schema.org Event 結構化資料，直接取日期與地點
    let event = "";
    for (const m of html.matchAll(/<script[^>]+application\/ld\+json[^>]*>([\s\S]*?)<\/script>/gi)) {
      try {
        const stack = [JSON.parse(m[1])];
        while (stack.length && !event) {
          const o = stack.pop();
          if (Array.isArray(o)) { stack.push(...o); continue; }
          if (!o || typeof o !== "object") continue;
          if (/Event/.test([].concat(o["@type"] || []).join(",")) && o.startDate) {
            const s = String(o.startDate), e = o.endDate ? String(o.endDate) : "";
            const t1 = (s.match(/T(\d{2}:\d{2})/) || [])[1], t2 = (e.match(/T(\d{2}:\d{2})/) || [])[1];
            const loc = o.location || {}, a = loc.address;
            const place = [loc.name, typeof a === "string" ? a : a && ((a.addressLocality || "") + (a.streetAddress || ""))].filter(Boolean).join(" ");
            event = "日期：" + s.slice(0, 10) + (t1 ? " " + t1 + (t2 ? "-" + t2 : "") : "") + (place ? "\n地點：" + place : "");
          } else if (o["@graph"]) stack.push(o["@graph"]);
        }
      } catch {}
      if (event) break;
    }

    return json({
      finalUrl: res.url,
      event,
      title: meta("og:title") || (t ? decode(t[1]).trim() : ""),
      description: meta("og:description") || meta("description"),
      text,
    });

    function json(obj, status = 200) { return new Response(JSON.stringify(obj), { status, headers: cors }); }
    function decode(s) {
      return s.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'").replace(/&#x([0-9a-f]+);/gi, (_, x) => String.fromCodePoint(parseInt(x, 16)))
        .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d));
    }
  },
};
