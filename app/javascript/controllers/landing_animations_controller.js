import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('Landing animations controller connected');
    this.initializeAnimations();
  }

  initializeAnimations() {
    if (typeof gsap === 'undefined') {
      console.error('GSAP not loaded');
      return;
    }

    gsap.registerPlugin(ScrollTrigger);

    // Initial page load animations
    this.heroEntryAnimations();

    // Scroll-triggered animations
    this.scrollAnimations();
  }

  heroEntryAnimations() {
    // Stagger the initial load animations
    const tl = gsap.timeline({ defaults: { ease: "power3.out" }});


    // Navbar fade in
    tl.from('.nav-content', {
      y: -50,
      opacity: 0,
      duration: 1.2,
    })

    // Hero title animation with split text effect
    .from('.hero-title', {
      y: 100,
      opacity: 0,
      duration: 1.2,
      stagger: 0.2
    }, "-=0.5")

    // Phone mockup animation
    .from('.hero-mockup', {
      y: 100,
      scale: 0.7,
      opacity: 0,
      duration: 1.3,
      ease: "back.out(1.7)"
    }, "-=0.8");
  }

  scrollAnimations() {
    // Create a master timeline for scroll animations
    const masterTl = gsap.timeline();

    // Plaid & Cards Logo Section
    const plaidTl = gsap.timeline({
      scrollTrigger: {
        trigger: '.plaid-logos',
        start: 'top 55%',
        end: 'bottom 40%',
        scrub: 1,
        // markers: true
      }
    });

    plaidTl.from('.plaid-logos', {
      x: -200,
      opacity: 0,
      duration: 1.5,
      ease: "power3.out"
    });

    masterTl.add(plaidTl);

    // Animated cards with stagger effect and timeline
    const cardsTl = gsap.timeline({
      scrollTrigger: {
        trigger: '.assets-card',
        start: 'top 85%',
        end: 'top 35%',
        scrub: 1,
        // markers: true
      }
    });

    const cards = [
      {
        element: '.assets-card',
        direction: 'left'
      },
      {
        element: '.networth-card',
        direction: 'bottom'
      },
      {
        element: '.expenses-card',
        direction: 'right'
      }
    ];

    // Add each card animation to the cards timeline with stagger
    cards.forEach(({ element, direction }, index) => {
      const xValue = direction === 'left' ? -100 : direction === 'right' ? 100 : 0;
      const yValue = direction === 'bottom' ? 100 : 0;

      cardsTl.from(element, {
        x: xValue,
        y: yValue,
        opacity: 0,
        scale: 0.9,
        rotation: direction === 'left' ? -10 : direction === 'right' ? 10 : 0,
        duration: 1.5,
        ease: "power2.out"
      }, index * 0.3); // Stagger each card by 0.3 seconds
    });

    masterTl.add(cardsTl, "-=0.5"); // Overlap slightly with previous animation

    // Side text animations timeline
    const textTl = gsap.timeline({
      scrollTrigger: {
        trigger: '.app-details',
        start: 'top 50%',
        end: 'bottom 40%',
        scrub: 1,
        // markers: true
      }
    });

    const sideElements = ['.app-details', '.track-text'];
    sideElements.forEach((element, index) => {
      textTl.from(element, {
        x: 100,
        opacity: 0,
        duration: 1,
        ease: "power2.out"
      }, index * 0.2); // Stagger text elements
    });

    masterTl.add(textTl, "-=0.3");

    // CTA Button animation timeline
    const ctaTl = gsap.timeline({
      scrollTrigger: {
        trigger: '.cta-button',
        start: 'top 90%',
        end: 'top 70%',
        scrub: 1,
        // markers: true
      }
    });

    ctaTl.from('.cta-button', {
      y: 50,
      scale: 0.9,
      opacity: 0,
      duration: 1,
      ease: "back.out(1.7)"
    });

    masterTl.add(ctaTl);

    // Add some cool effects when cards become active
    cards.forEach(({ element }) => {
      ScrollTrigger.create({
        trigger: element,
        start: 'top center',
        toggleClass: 'active',
        onEnter: () => {
          gsap.to(element, {
            scale: 1.02,
            duration: 0.3,
            ease: "power2.out"
          });
        },
        onLeave: () => {
          gsap.to(element, {
            scale: 1,
            duration: 0.3,
            ease: "power2.in"
          });
        }
      });
    });

    return masterTl; // Return the master timeline for potential further control
  }
}
