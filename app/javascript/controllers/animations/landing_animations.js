import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

document.addEventListener('DOMContentLoaded', () => {

  // Initial animation for nav content
  gsap.from('.nav-content', {
    y: -100,
    opacity: 0,
    duration: 1,
    ease: 'power3.out'
  });

  // Hero title animation
  gsap.from('.hero-title', {
    scrollTrigger: {
      trigger: '.hero-title',
      start: 'top 80%',
      end: 'top 20%',
      scrub: 1
    },
    y: 100,
    opacity: 0,
    duration: 1
  });

  // Mobile mockup animation
  gsap.from('.hero-mockup', {
    scrollTrigger: {
      trigger: '.hero-mockup',
      start: 'top 80%',
      end: 'top 30%',
      scrub: 1
    },
    scale: 0.8,
    opacity: 0,
    duration: 1.5
  });

  // Plaid logos animation
  gsap.from('.plaid-logos', {
    scrollTrigger: {
      trigger: '.plaid-logos',
      start: 'top 80%',
      end: 'top 40%',
      scrub: 1,
      markers: true
    },
    x: -100,
    opacity: 0,
    duration: 1
  });

  // Cards animations with stagger
  const cards = ['.assets-card', '.networth-card', '.expenses-card'];
  cards.forEach((card, index) => {
    gsap.from(card, {
      scrollTrigger: {
        trigger: card,
        start: 'top 85%',
        end: 'top 35%',
        scrub: 1,
        markers: true
      },
      x: index % 2 === 0 ? -100 : 100,
      y: 50,
      opacity: 0,
      rotation: index % 2 === 0 ? -10 : 10,
      duration: 1,
      delay: index * 0.2
    });
  });

  // App details text animation
  gsap.from('.app-details', {
    scrollTrigger: {
      trigger: '.app-details',
      start: 'top 80%',
      end: 'top 40%',
      scrub: 1
    },
    x: 100,
    opacity: 0,
    duration: 1
  });

  // Track text animation
  gsap.from('.track-text', {
    scrollTrigger: {
      trigger: '.track-text',
      start: 'top 80%',
      end: 'top 40%',
      scrub: 1
    },
    x: 100,
    opacity: 0,
    duration: 1
  });

  // CTA button animation
  gsap.from('.cta-button', {
    scrollTrigger: {
      trigger: '.cta-button',
      start: 'top 90%',
      end: 'top 70%',
      scrub: 1
    },
    y: 50,
    opacity: 0,
    duration: 1
  });
});
