# 🔗 URL Shortener - CoinGecko Engineering Written Assignment

In this document, I will outline the strategies and design decisions I made while developing the URL Shortener service.

## 🔗 URL Shortening

source: [short_code_generator.rb](../app/lib/short_code_generator.rb)

The URL shortening process produces short code which is made of two parts joined together:

```
[Random Prefix (7 chars)] + [Base62 Encoded ID]
```

### Random Prefix (7 chars)

This 7 character random prefix is sampled from the Base62 character set (`a-zA-Z0-9`).

The random prefix serves two purposes:
1. **Obfuscation**: It makes the short URL **less predictable and more resistant to brute-force attacks**, as attackers cannot easily guess the next short code based on the previous ones.
2. **Uniqueness**: It adds an additional layer of uniqueness to the short code, **reducing the likelihood of collisions** when multiple URLs are shortened in a short period of time.

### Base62 Encoded ID

This numeric ID is generated from the database record's primary key (ID) and encoded into a Base62 string, making the short code compact and URL-friendly.

| ID Range | Base62 Length | Example |
|---|---|---|
| 0 | 1 char | `0` |
| 1 – 61 | 1 char | `1`, `Z` |
| 62 – 3,843 | 2 chars | `10`, `ZZ` |
| 3,844 – 238,327 | 3 chars | `100` |
| 238,328 – 14,776,335 | 4 chars | `1000` |
| 14,776,336 – 916,132,831 | 5 chars | ... |
| 916,132,832 – 56,800,235,583 | 6 chars | ... |
| 56,800,235,584 – 3,521,614,606,207 | 7 chars | ... |
| 3,521,614,606,208 – 218,340,105,584,895 | 8 chars | ... |

---

### How Many IDs Before Hitting 15 Characters?

Our total short code length is:

```
total_length = 7 (prefix) + base62_length(id)
```

To stay **under 15 characters**, the Base62-encoded ID must be **≤ 7 characters** (since `7 + 7 = 14`).

The maximum value encodable in 7 Base62 characters is:

```
62^7 - 1 = 3,521,614,606,207
```

We can create up to **3,521,614,606,207 URLs** (~3.5 trillion) before the short code exceeds 14 characters.

At 8 Base62 characters, the total code length becomes **15 characters**, which you'd hit at ID `3,521,614,606,208`.

## 📌 Background jobs

## 🔌 Action Cable

## 🖥️ Frontend & UI/UX

## 🎯 Caching

## 🔒 Security

## 📈 Scalability

## 🚀 Deployment