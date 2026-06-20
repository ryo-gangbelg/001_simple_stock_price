import sys
import requests
from colorama import init, Fore, Style

sys.stdout.reconfigure(encoding="utf-8")
init()

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}


def get_stock_price(ticker: str) -> None:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?interval=1d&range=1d"
    try:
        r = requests.get(url, headers=HEADERS, timeout=10)
        r.raise_for_status()
        meta = r.json()["chart"]["result"][0]["meta"]

        name = meta.get("longName") or ticker
        currency = meta.get("currency", "")
        current = meta.get("regularMarketPrice", 0)
        prev_close = meta.get("chartPreviousClose", 0)
        change = round(current - prev_close, 2)
        change_pct = round((change / prev_close) * 100, 2) if prev_close else 0
        sign = "+" if change >= 0 else ""

        print()
        print(f"  {Fore.CYAN}{name} ({ticker.upper()}){Style.RESET_ALL}")
        print(f"  現在値: {current:,.2f} {currency}")
        print(f"  前日比: {sign}{change:,.2f} ({sign}{change_pct:.2f}%)")
        print()

    except Exception:
        print(f"{Fore.RED}エラー: '{ticker}' の株価を取得できませんでした。ティッカーコードを確認してください。{Style.RESET_ALL}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("使い方: python stock_price.py <TICKER> [TICKER ...]")
        sys.exit(1)

    for ticker in sys.argv[1:]:
        get_stock_price(ticker)
