Rails.application.config.session_store :cookie_store,
  key: "_link_shortener_session",
  expire_after: 1.month
