/// Stripe's publishable key is safe to ship in the client by design (it can
/// only create charges against the account it belongs to, never read data or
/// move money out) — unlike the secret key, which stays backend-only and is
/// used to create/verify payment intents from the server.
class StripeConfig {
  StripeConfig._();

  static const String publishableKey =
      'pk_test_51TzfanGsrStj7tkbDoLRout1KSTwThrSB7lLqgmapLPPtJXgNAJk5r2OiDRayzrYpQ8d9Y5xqjsKiJuNS67zTppC004mPhJTRW';
}
