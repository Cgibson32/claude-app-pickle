/**
 * SubscriptionService
 *
 * In-App Purchase / Subscription abstraction for the App Store.
 * Currently returns mock data so the paywall UI works.
 * When ready to go live, install the Capacitor IAP plugin and uncomment the real implementation.
 *
 * ─── SETUP WHEN READY ─────────────────────────────────────────────────────────
 *
 * 1. Install the IAP plugin:
 *    npm install @revenuecat/purchases-capacitor
 *
 * 2. Configure RevenueCat:
 *    - Create a RevenueCat account at https://www.revenuecat.com
 *    - Add your App Store Connect app
 *    - Create products in App Store Connect:
 *      - com.picklepro.app.premium.monthly  ($4.99/mo)
 *      - com.picklepro.app.premium.annual   ($29.99/yr)
 *    - Configure offerings in RevenueCat dashboard
 *    - Get your API key from RevenueCat → Project Settings → API Keys
 *
 * 3. Add to .env:
 *    VITE_REVENUECAT_API_KEY=your_api_key
 *
 * 4. Uncomment the RevenueCat implementation below.
 *
 * ────────────────────────────────────────────────────────────────────────────────
 */

import { storageGet, storageSet, STORAGE_KEYS } from './StorageService';
import { isNative } from './NativeService';

// ─── Product Definitions ─────────────────────────────────────────────────────

export const PRODUCTS = {
  MONTHLY: {
    id: 'com.picklepro.app.premium.monthly',
    name: 'PicklePro Premium',
    period: 'Monthly',
    price: '$4.99',
    priceAmount: 4.99,
  },
  ANNUAL: {
    id: 'com.picklepro.app.premium.annual',
    name: 'PicklePro Premium',
    period: 'Annual',
    price: '$29.99',
    priceAmount: 29.99,
    savings: '50%',
  },
};

export const PREMIUM_FEATURES = [
  { label: 'AI Coaching Insights', icon: '🤖', description: 'Personalized coaching powered by AI' },
  { label: 'Unlimited Session History', icon: '📓', description: 'Full journal with detailed analytics' },
  { label: 'Advanced Drill Library', icon: '🎯', description: 'Premium drills with video guides' },
  { label: 'Custom Mental Game Plans', icon: '🧠', description: 'Tailored mental training programs' },
  { label: 'Progress Analytics', icon: '📊', description: 'Deep insights into your growth patterns' },
  { label: 'Priority Support', icon: '⚡', description: 'Direct access to coaching support' },
];

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Initialize the subscription service. Call once on app start.
 */
export async function initSubscriptions() {
  if (!isNative) return;

  // Uncomment when RevenueCat is configured:
  // const { Purchases } = await import('@revenuecat/purchases-capacitor');
  // await Purchases.configure({
  //   apiKey: import.meta.env.VITE_REVENUECAT_API_KEY,
  // });
}

/**
 * Returns the current subscription status.
 *
 * @returns {Promise<SubscriptionStatus>}
 */
export async function getSubscriptionStatus() {
  // Check local override first (for testing / gifted access)
  const meta = storageGet(STORAGE_KEYS.APP_META, {});
  if (meta.premiumOverride) {
    return { isPremium: true, plan: 'override', expiresAt: null };
  }

  if (!isNative) {
    return { isPremium: false, plan: null, expiresAt: null };
  }

  // Uncomment when RevenueCat is configured:
  // try {
  //   const { Purchases } = await import('@revenuecat/purchases-capacitor');
  //   const { customerInfo } = await Purchases.getCustomerInfo();
  //   const premium = customerInfo.entitlements.active['premium'];
  //   return {
  //     isPremium: !!premium,
  //     plan: premium?.productIdentifier || null,
  //     expiresAt: premium?.expirationDate || null,
  //   };
  // } catch {
  //   return { isPremium: false, plan: null, expiresAt: null };
  // }

  return { isPremium: false, plan: null, expiresAt: null };
}

/**
 * Initiates a purchase flow for the given product.
 *
 * @param {'MONTHLY' | 'ANNUAL'} planKey
 * @returns {Promise<{ success: boolean, error?: string }>}
 */
export async function purchaseProduct(planKey) {
  const product = PRODUCTS[planKey];
  if (!product) return { success: false, error: 'Invalid product' };

  if (!isNative) {
    // Mock purchase for web testing
    const meta = storageGet(STORAGE_KEYS.APP_META, {});
    storageSet(STORAGE_KEYS.APP_META, { ...meta, premiumOverride: true });
    return { success: true };
  }

  // Uncomment when RevenueCat is configured:
  // try {
  //   const { Purchases } = await import('@revenuecat/purchases-capacitor');
  //   const offerings = await Purchases.getOfferings();
  //   const pkg = offerings.current?.availablePackages.find(
  //     p => p.product.identifier === product.id
  //   );
  //   if (!pkg) return { success: false, error: 'Product not found' };
  //   await Purchases.purchasePackage({ aPackage: pkg });
  //   return { success: true };
  // } catch (err) {
  //   if (err.userCancelled) return { success: false, error: 'cancelled' };
  //   return { success: false, error: err.message };
  // }

  return { success: false, error: 'Purchases not configured' };
}

/**
 * Restores previous purchases (required by App Store guidelines).
 *
 * @returns {Promise<{ isPremium: boolean }>}
 */
export async function restorePurchases() {
  if (!isNative) {
    const meta = storageGet(STORAGE_KEYS.APP_META, {});
    return { isPremium: !!meta.premiumOverride };
  }

  // Uncomment when RevenueCat is configured:
  // try {
  //   const { Purchases } = await import('@revenuecat/purchases-capacitor');
  //   const { customerInfo } = await Purchases.restorePurchases();
  //   return { isPremium: !!customerInfo.entitlements.active['premium'] };
  // } catch {
  //   return { isPremium: false };
  // }

  return { isPremium: false };
}
