use crate::model::DisplayTitle;

/// 账户卡片标题：冒号优先，否则首个空格；账户名优先，重复 token 折叠。
pub(crate) fn display(site_name: &str, account_name: &str) -> DisplayTitle {
    let (title, implied) = split(site_name);
    let stored = account_name.trim();
    let subtitle = if !stored.is_empty() {
        Some(stored.to_string())
    } else if implied.is_empty() {
        None
    } else {
        Some(implied)
    };
    DisplayTitle { title, subtitle }
}

fn split(name: &str) -> (String, String) {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        return (String::new(), String::new());
    }
    // 首字符是冒号时按空格回退，与两端既有实现一致
    if let Some(index) = trimmed.find(':') {
        if index > 0 {
            return (
                trimmed[..index].trim().to_string(),
                collapse(trimmed[index + 1..].trim()),
            );
        }
    }
    match trimmed.split_once(' ') {
        Some((site, rest)) => (site.trim().to_string(), collapse(rest.trim())),
        None => (trimmed.to_string(), String::new()),
    }
}

/// `ada ada` → `ada`；其余原样。
fn collapse(rest: &str) -> String {
    let tokens: Vec<&str> = rest.split(' ').filter(|token| !token.is_empty()).collect();
    if tokens.len() >= 2 && tokens.iter().all(|token| *token == tokens[0]) {
        tokens[0].to_string()
    } else {
        rest.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn expect(site: &str, account: &str) -> (String, Option<String>) {
        let display = display(site, account);
        (display.title, display.subtitle)
    }

    #[test]
    fn colon_wins() {
        assert_eq!(
            expect("OpenAI:me@x.com", ""),
            ("OpenAI".into(), Some("me@x.com".into()))
        );
    }

    #[test]
    fn space_fallback() {
        assert_eq!(
            expect("GitHub ada", ""),
            ("GitHub".into(), Some("ada".into()))
        );
    }

    #[test]
    fn repeated_account_token_collapses() {
        assert_eq!(
            expect("GitHub:ada ada", ""),
            ("GitHub".into(), Some("ada".into()))
        );
    }

    #[test]
    fn stored_account_name_is_preferred() {
        assert_eq!(
            expect("GitHub:ada", "ada@example.com"),
            ("GitHub".into(), Some("ada@example.com".into()))
        );
    }

    #[test]
    fn empty_everything_has_no_subtitle() {
        assert_eq!(expect("", ""), (String::new(), None));
        assert_eq!(expect("Acme", ""), ("Acme".into(), None));
    }
}
