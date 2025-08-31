"use client";

import Image from "next/image";
import Link from "next/link";
import { motion, useInView, animate, Variants } from "framer-motion";
import { useRef, useState, useEffect } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faRocket, faUsers, faTrophy, faHandshake, faMobileAlt, faChartLine, faDownload, faStar } from "@fortawesome/free-solid-svg-icons";

// Animation variants for slide-in effects
const slideInVariants: Variants = {
  hidden: { opacity: 0, x: -50 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.6, ease: "easeOut" } },
};

// Animation variants for card scaling
const cardVariants: Variants = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.5, ease: "easeOut" } },
};

// Animation variants for video entrance
const videoVariants: Variants = {
  hidden: { opacity: 0, y: 50 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" } },
};

export default function Home() {
  // Refs for scroll-triggered animations
  const aboutRef = useRef(null);
  const howItWorksRef = useRef(null);
  const mobileAppRef = useRef(null);
  const statsRef = useRef(null);
  const partnersRef = useRef(null);
  const ctaRef = useRef(null);

  const aboutInView = useInView(aboutRef, { once: true, margin: "-100px" });
  const howItWorksInView = useInView(howItWorksRef, { once: true, margin: "-100px" });
  const mobileAppInView = useInView(mobileAppRef, { once: true, margin: "-100px" });
  const statsInView = useInView(statsRef, { once: true, margin: "-100px" });
  const partnersInView = useInView(partnersRef, { once: true, margin: "-100px" });
  const ctaInView = useInView(ctaRef, { once: true, margin: "-100px" });

  // States for animated counters
  const [studentCount, setStudentCount] = useState(0);
  const [companyCount, setCompanyCount] = useState(0);

  // Detect dark mode
  const [isDarkMode, setIsDarkMode] = useState(false);

  // State for current screenshot index in mobile view
  const [currentScreenshot, setCurrentScreenshot] = useState(0);

  useEffect(() => {
    // Check for dark mode preference
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    setIsDarkMode(mediaQuery.matches);

    const handleChange = (e: MediaQueryListEvent) => setIsDarkMode(e.matches);
    mediaQuery.addEventListener("change", handleChange);
    return () => mediaQuery.removeEventListener("change", handleChange);
  }, []);

  useEffect(() => {
    if (statsInView) {
      animate(0, 20000, {
        duration: 5,
        onUpdate: (latest) => setStudentCount(Math.floor(latest)),
      });
      animate(0, 120, {
        duration: 5,
        onUpdate: (latest) => setCompanyCount(Math.floor(latest)),
      });
    }
  }, [statsInView]);

  // Mobile app screenshots with light/dark variants
  const screenshots = [
    { src: isDarkMode ? "/dashboard-d.jpg" : "/dashboard-l.jpg", alt: "Dashboard Screenshot" },
    { src: isDarkMode ? "/challenges-d.jpg" : "/challenges-l.jpg", alt: "Challenges Screenshot" },
  ];

  // Handle screenshot navigation
  const nextScreenshot = () => {
    setCurrentScreenshot((prev) => (prev + 1) % screenshots.length);
  };

  const prevScreenshot = () => {
    setCurrentScreenshot((prev) => (prev - 1 + screenshots.length) % screenshots.length);
  };

  // Subscription tiers for companies
  const subscriptionTiers = [
    {
      title: "Free Tier",
      price: "Free",
      challenges: "1 challenge per month",
      benefits: [
        "Access to student submissions",
        "Basic analytics dashboard",
        "Community support",
      ],
    },
    {
      title: "Pro Tier",
      price: "$6/month",
      challenges: "10 challenges per month",
      benefits: [
        "Access to student submissions",
        "Advanced analytics dashboard",
        "Priority support",
        "Custom challenge branding",
      ],
    },
    {
      title: "Enterprise Tier",
      price: "$12/month",
      challenges: "Unlimited challenges per month",
      benefits: [
        "Access to student submissions",
        "Advanced analytics dashboard",
        "Dedicated account manager",
        "Custom challenge branding",
        "Priority talent matching",
      ],
    },
  ];

  return (
    <div className="flex flex-col flex-1 bg-[var(--background)] overflow-x-hidden">
      <main className="flex-1">
        {/* Hero Section with Wavy Animation */}
        <section className="relative bg-[var(--primary)] text-[var(--background)] py-20 overflow-hidden">
          <div className="absolute inset-0">
            <svg
              className="w-full h-full"
              preserveAspectRatio="none"
              viewBox="0 0 1440 200"
            >
              <path
                fill="var(--secondary)"
                fillOpacity="0.3"
                d="M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z"
              >
                <animate
                  attributeName="d"
                  values="
                    M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z;
                    M0,128C240,64,480,96,720,160C960,128,1200,64,1440,128V200H0Z;
                    M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z"
                  dur="10s"
                  repeatCount="indefinite"
                />
              </path>
            </svg>
          </div>
          <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <Image
              src="/logo.png"
              alt="Skillproof Logo"
              width={200}
              height={80}
              priority
              className="mx-auto mb-8 h-20 w-auto"
            />
            <h1 className="text-5xl sm:text-6xl font-bold mb-6">
              Skillproof: Empowering Kenyan Talent
            </h1>
            <p className="text-xl sm:text-2xl max-w-3xl mx-auto mb-10">
              Gain real-world experience through challenges set by Kenya&apos;s top companies, from government to private sectors. Skillproof connects aspiring professionals with opportunities to build skills, earn recognition, and advance careers.
            </p>
            <div className="flex justify-center gap-6">
              <Link
                href="/auth/register"
                className="flex items-center gap-2 bg-[var(--accent)] text-[var(--background)] px-8 py-4 rounded-full font-medium text-lg hover:bg-[oklch(75%_0.1_50)] transition-colors"
              >
                <FontAwesomeIcon icon={faRocket} />
                Get Started
              </Link>
              <Link
                href="/auth/login"
                className="flex items-center gap-2 border border-[var(--background)] text-[var(--background)] px-8 py-4 rounded-full font-medium text-lg hover:bg-[var(--background)] hover:text-[var(--primary)] transition-colors"
              >
                <FontAwesomeIcon icon={faUsers} />
                Login
              </Link>
            </div>
          </div>
        </section>

        {/* About Section */}
        <section
          id="about"
          ref={aboutRef}
          className="py-20 bg-[var(--neutral)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={aboutInView ? "visible" : "hidden"}
              variants={slideInVariants}
              className="flex flex-col md:flex-row items-center gap-8"
            >
              <div className="md:w-1/2 text-center md:text-left">
                <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 flex items-center justify-center md:justify-start gap-3">
                  <FontAwesomeIcon icon={faTrophy} className="text-[var(--secondary)]" />
                  About Skillproof
                </h2>
                <p className="text-lg text-[var(--foreground)]/80 mb-6">
                  Skillproof bridges the gap between Kenyan students and industry by offering real-world challenges from leading companies. Students and graduates complete tasks, earn points, and build a portfolio of experience to enhance their job applications.
                </p>
                <p className="text-lg text-[var(--foreground)]/80">
                  Our platform fosters collaboration between educational institutions, students, and employers, ensuring that Kenyan talent is equipped with practical skills demanded by the job market. Whether you&apos;re a recent graduate or a seasoned professional looking to upskill, Skillproof provides tailored challenges to help you grow.
                </p>
              </div>
              <motion.div
                initial="hidden"
                animate={aboutInView ? "visible" : "hidden"}
                variants={{ ...slideInVariants, hidden: { opacity: 0, x: 50 } }}
                className="md:w-1/2"
              >
                <Image
                  src="/students-working.jpg"
                  alt="Students working"
                  width={600}
                  height={400}
                  className="w-full max-w-[400px] md:max-w-[600px] mx-auto rounded-lg shadow-md"
                />
              </motion.div>
            </motion.div>
          </div>
        </section>

        {/* How It Works Section */}
        <section
          ref={howItWorksRef}
          className="py-20 bg-[var(--background)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={howItWorksInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 text-center flex items-center justify-center gap-3">
                <FontAwesomeIcon icon={faHandshake} className="text-[var(--secondary)]" />
                How It Works
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-3xl mx-auto text-center mb-10">
                Skillproof is designed to be intuitive and effective. Here&apos;s a step-by-step breakdown of how students and companies can engage with the platform to achieve mutual benefits.
              </p>
            </motion.div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <motion.div
                initial="hidden"
                animate={howItWorksInView ? "visible" : "hidden"}
                variants={slideInVariants}
                className="text-center p-6 bg-[var(--neutral)] rounded-lg shadow-sm"
              >
                <h3 className="text-xl font-semibold text-[var(--foreground)] mb-4">1. Join a Challenge</h3>
                <p className="text-[var(--foreground)]/80 mb-4">
                  Students sign up and browse challenges posted by Kenyan companies. Each challenge is crafted to simulate real-world tasks, providing hands-on experience in various fields.
                </p>
                <p className="text-[var(--foreground)]/80">
                  Companies can post challenges to source innovative solutions and identify top talent early.
                </p>
              </motion.div>
              <motion.div
                initial="hidden"
                animate={howItWorksInView ? "visible" : "hidden"}
                variants={{ ...slideInVariants, hidden: { opacity: 0, x: 50 } }}
                className="text-center p-6 bg-[var(--neutral)] rounded-lg shadow-sm"
              >
                <h3 className="text-xl font-semibold text-[var(--foreground)] mb-4">2. Submit Your Work</h3>
                <p className="text-[var(--foreground)]/80 mb-4">
                  Complete tasks and submit solutions to earn points and feedback. Our review system ensures constructive input from industry experts. Top students in each challenge receive exclusive rewards, such as scholarships, internships, or mentorship opportunities.
                </p>
                <p className="text-[var(--foreground)]/80">
                  Companies review submissions, provide feedback, and potentially offer internships or job opportunities to standout participants.
                </p>
              </motion.div>
              <motion.div
                initial="hidden"
                animate={howItWorksInView ? "visible" : "hidden"}
                variants={{ ...slideInVariants, hidden: { opacity: 0, x: -50 } }}
                className="text-center p-6 bg-[var(--neutral)] rounded-lg shadow-sm"
              >
                <h3 className="text-xl font-semibold text-[var(--foreground)] mb-4">3. Build Your Portfolio</h3>
                <p className="text-[var(--foreground)]/80 mb-4">
                  Use your achievements to showcase experience on job applications. Skillproof portfolios are verifiable and highlight practical skills.
                </p>
                <p className="text-[var(--foreground)]/80">
                  Companies gain access to a pool of pre-vetted talent, streamlining their recruitment process.
                </p>
              </motion.div>
            </div>
          </div>
        </section>

        {/* Subscription Tiers Section */}
        <section
          className="py-20 bg-[var(--neutral)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={howItWorksInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 text-center flex items-center justify-center gap-3">
                <FontAwesomeIcon icon={faStar} className="text-[var(--secondary)]" />
                Subscription Plans for Companies
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-3xl mx-auto text-center mb-10">
                Companies can choose from flexible subscription tiers to post challenges and engage with top talent. Each tier offers unique benefits to suit your recruitment and innovation needs.
              </p>
            </motion.div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {subscriptionTiers.map((tier, index) => (
                <motion.div
                  key={index}
                  initial="hidden"
                  animate={howItWorksInView ? "visible" : "hidden"}
                  variants={cardVariants}
                  className="p-6 bg-[var(--background)] rounded-lg shadow-md text-center"
                >
                  <h3 className="text-2xl font-semibold text-[var(--foreground)] mb-4">{tier.title}</h3>
                  <p className="text-3xl font-bold text-[var(--accent)] mb-4">{tier.price}</p>
                  <p className="text-lg text-[var(--foreground)]/80 mb-4">{tier.challenges}</p>
                  <ul className="text-left text-[var(--foreground)]/80 mb-6">
                    {tier.benefits.map((benefit, i) => (
                      <li key={i} className="flex items-center gap-2 mb-2">
                        <FontAwesomeIcon icon={faStar} className="text-[var(--secondary)]" />
                        {benefit}
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/auth/register"
                    className="inline-block bg-[var(--accent)] text-[var(--background)] px-6 py-3 rounded-full font-medium hover:bg-[oklch(75%_0.1_50)] transition-colors"
                  >
                    Choose Plan
                  </Link>
                </motion.div>
              ))}
            </div>
          </div>
        </section>

        {/* Mobile App Section */}
        <section
          ref={mobileAppRef}
          className="py-20 bg-[var(--neutral)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={mobileAppInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 text-center flex items-center justify-center gap-3">
                <FontAwesomeIcon icon={faMobileAlt} className="text-[var(--secondary)]" />
                Access Skillproof on Mobile
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-3xl mx-auto text-center mb-10">
                Our dedicated mobile application is designed exclusively for students, allowing them to access challenges, submit work, track progress, and manage their portfolios on the go. The app provides a seamless experience with intuitive navigation and real-time notifications to keep students engaged with new opportunities.
              </p>
              <div className="flex justify-center mb-10">
                <a
                  href="/downloads/SkillProof.apk"
                  download
                  className="flex items-center gap-2 bg-[var(--accent)] text-[var(--background)] px-8 py-4 rounded-full font-medium text-lg hover:bg-[oklch(75%_0.1_50)] transition-colors"
                >
                  <FontAwesomeIcon icon={faDownload} />
                  Download App
                </a>
              </div>
            </motion.div>
            {/* Mobile View: Slidable Screenshots */}
            <div className="block sm:hidden relative max-w-[200px] mx-auto">
              <motion.div
                initial="hidden"
                animate={mobileAppInView ? "visible" : "hidden"}
                variants={videoVariants}
              >
                <Image
                  src={screenshots[currentScreenshot].src}
                  alt={screenshots[currentScreenshot].alt}
                  width={200}
                  height={400}
                  className="mx-auto rounded-lg shadow-md w-full"
                />
              </motion.div>
              <div className="flex justify-between mt-4 w-full px-2">
                <button
                  onClick={prevScreenshot}
                  className="bg-[var(--accent)] text-[var(--background)] px-4 py-2 rounded-full text-sm"
                >
                  Prev
                </button>
                <button
                  onClick={nextScreenshot}
                  className="bg-[var(--accent)] text-[var(--background)] px-4 py-2 rounded-full text-sm"
                >
                  Next
                </button>
              </div>
            </div>
            {/* Desktop View: Screenshot, Video, Screenshot */}
            <div className="hidden sm:grid sm:grid-cols-3 gap-6">
              <motion.div
                initial="hidden"
                animate={mobileAppInView ? "visible" : "hidden"}
                variants={{
                  hidden: { opacity: 0, y: 50 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut", delay: 0 } },
                }}
              >
                <Image
                  src={screenshots[0].src}
                  alt={screenshots[0].alt}
                  width={300}
                  height={600}
                  className="mx-auto rounded-lg shadow-md w-[200px] sm:w-[250px] md:w-[300px]"
                />
              </motion.div>
              <motion.div
                initial="hidden"
                animate={mobileAppInView ? "visible" : "hidden"}
                variants={{
                  hidden: { opacity: 0, y: 50 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut", delay: 0.2 } },
                }}
                className="relative mx-auto rounded-lg shadow-md w-[200px] sm:w-[250px] md:w-[300px]"
              >
                {/* Video */}
                <video
                  src="/videos/skillproof-demo.mp4"
                  autoPlay
                  loop
                  muted
                  playsInline
                  className="w-full h-auto rounded-lg object-cover aspect-[300/600]"
                />
                {/* Overlay */}
                <div className="absolute inset-0 bg-gradient-to-b from-transparent to-[var(--primary)]/30 flex items-end justify-center pb-6">
                  <p className="text-[var(--background)] text-lg font-semibold bg-[var(--accent)]/80 px-6 py-2 rounded-full">
                    Discover Skillproof
                  </p>
                </div>
              </motion.div>
              <motion.div
                initial="hidden"
                animate={mobileAppInView ? "visible" : "hidden"}
                variants={{
                  hidden: { opacity: 0, y: 50 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut", delay: 0.4 } },
                }}
              >
                <Image
                  src={screenshots[1].src}
                  alt={screenshots[1].alt}
                  width={300}
                  height={600}
                  className="mx-auto rounded-lg shadow-md w-[200px] sm:w-[250px] md:w-[300px]"
                />
              </motion.div>
            </div>
          </div>
        </section>

        {/* Stats Section */}
        <section
          ref={statsRef}
          className="py-20 bg-[var(--background)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={statsInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 text-center flex items-center justify-center gap-3">
                <FontAwesomeIcon icon={faChartLine} className="text-[var(--secondary)]" />
                Our Growing Community
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-3xl mx-auto text-center mb-10">
                Join thousands of students and hundreds of companies already benefiting from Skillproof.
              </p>
            </motion.div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 text-center">
              <motion.div
                initial="hidden"
                animate={statsInView ? "visible" : "hidden"}
                variants={slideInVariants}
                className="p-6 bg-[var(--neutral)] rounded-lg shadow-sm"
              >
                <h3 className="text-5xl font-bold text-[var(--accent)] mb-2">{studentCount.toLocaleString()}+</h3>
                <p className="text-xl text-[var(--foreground)]">Students Empowered</p>
              </motion.div>
              <motion.div
                initial="hidden"
                animate={statsInView ? "visible" : "hidden"}
                variants={{ ...slideInVariants, hidden: { opacity: 0, x: 50 } }}
                className="p-6 bg-[var(--neutral)] rounded-lg shadow-sm"
              >
                <h3 className="text-5xl font-bold text-[var(--accent)] mb-2">{companyCount.toLocaleString()}+</h3>
                <p className="text-xl text-[var(--foreground)]">Partner Companies</p>
              </motion.div>
            </div>
          </div>
        </section>

        {/* Partners Section */}
        <section
          ref={partnersRef}
          className="py-20 bg-[var(--neutral)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div
              initial="hidden"
              animate={partnersInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-8 text-center">
                Our Partners
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-3xl mx-auto text-center mb-10">
                We collaborate with leading Kenyan companies across government, private, and public sectors to provide real-world challenges. These partnerships ensure that challenges are relevant and impactful.
              </p>
            </motion.div>
            <motion.div
              initial="hidden"
              animate={partnersInView ? "visible" : "hidden"}
              variants={{ ...slideInVariants, hidden: { opacity: 0, x: 50 } }}
              className="grid grid-cols-2 md:grid-cols-4 gap-6"
            >
              {[1, 2, 3, 4].map((i) => (
                <Image
                  key={i}
                  src={`/partner-${i}.png`}
                  alt={`Partner ${i}`}
                  width={150}
                  height={100}
                  className="mx-auto opacity-70 hover:opacity-100 transition-opacity"
                />
              ))}
            </motion.div>
          </div>
        </section>

        {/* Call to Action */}
        <section
          ref={ctaRef}
          className="py-20 bg-[var(--background)]"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <motion.div
              initial="hidden"
              animate={ctaInView ? "visible" : "hidden"}
              variants={slideInVariants}
            >
              <h2 className="text-4xl font-bold text-[var(--foreground)] mb-6">
                Join Our Platform
              </h2>
              <p className="text-lg text-[var(--foreground)]/80 max-w-2xl mx-auto mb-8">
                Whether you&apos;re a student seeking experience or a company looking for talent, Skillproof is your platform for growth. Sign up today and start your journey.
              </p>
              <Link
                href="/auth/register"
                className="flex items-center gap-2 justify-center bg-[var(--accent)] text-[var(--background)] px-8 py-4 rounded-full font-medium text-lg hover:bg-[oklch(75%_0.1_50)] transition-colors mx-auto"
              >
                <FontAwesomeIcon icon={faRocket} />
                Sign Up Now
              </Link>
            </motion.div>
          </div>
        </section>
      </main>
    </div>
  );
}