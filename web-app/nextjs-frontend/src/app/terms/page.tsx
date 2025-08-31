"use client";

import { motion, useInView, Variants } from "framer-motion";
import { useRef } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faFileContract } from "@fortawesome/free-solid-svg-icons";
import WavyBackground from "@/components/WavyBackground";

// Animation variants for slide-in effects
const slideInVariants: Variants = {
  hidden: { opacity: 0, y: 50 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" } },
};

export default function Terms() {
  const contentRef = useRef(null);
  const contentInView = useInView(contentRef, { once: true, margin: "-100px" });

  return (
    <div className="flex flex-col min-h-screen bg-[var(--background)] relative overflow-x-hidden">
      {/* Wavy Animation Background */}
      <WavyBackground opacity={0.1} />
      <main className="flex-1 py-20 relative z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            ref={contentRef}
            initial="hidden"
            animate={contentInView ? "visible" : "hidden"}
            variants={slideInVariants}
          >
            <h1 className="text-4xl sm:text-5xl font-bold text-[var(--foreground)] mb-8 text-center flex items-center justify-center gap-3">
              <FontAwesomeIcon icon={faFileContract} className="text-[var(--secondary)]" />
              Terms of Service
            </h1>
            <div className="prose prose-lg text-[var(--foreground)]/80 max-w-4xl mx-auto">
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">1. Introduction</h2>
                <p>
                  Welcome to Skillproof, a platform connecting Kenyan students and companies through real-world challenges. By accessing or using our platform, you agree to be bound by these Terms of Service (&apos;Terms&apos;). These Terms govern your use of our website, mobile application, and related services.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">2. Eligibility</h2>
                <p>
                  To use Skillproof, you must be at least 13 years old. Students and companies must register with accurate information and maintain the confidentiality of their account credentials.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">3. User Responsibilities</h2>
                <p>
                  Users are responsible for their conduct on the platform. Students must submit original work for challenges, and companies must provide accurate challenge descriptions and feedback. Any misuse, including plagiarism or misrepresentation, may result in account suspension.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">4. Subscription Plans for Companies</h2>
                <p>
                  Companies can choose from subscription tiers (Free, Pro, Enterprise) to post challenges. Each tier includes specific benefits, as outlined on our platform. Payments are processed securely, and cancellations must follow our refund policy.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">5. Intellectual Property</h2>
                <p>
                  Content submitted by users remains their property, but by submitting, you grant Skillproof a non-exclusive license to display and use it for platform purposes. Skillproof owns all platform-related content, including logos and designs.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">6. Limitation of Liability</h2>
                <p>
                  Skillproof is not liable for any damages arising from platform use, including loss of data or opportunities. We strive to maintain a secure and reliable platform but cannot guarantee uninterrupted service.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">7. Changes to Terms</h2>
                <p>
                  We may update these Terms periodically. Users will be notified of significant changes via email or platform announcements. Continued use of Skillproof after changes constitutes acceptance of the new Terms.
                </p>
              </section>
              <section className="mb-8">
                <h2 className="text-2xl font-semibold text-[var(--foreground)] mb-4">8. Contact Us</h2>
                <p>
                  For questions or concerns about these Terms, please contact us at <a href="mailto:support@skillproof.me.ke" className="text-[var(--accent)] hover:underline">support@skillproof.me.ke</a>.
                </p>
              </section>
            </div>
          </motion.div>
        </div>
      </main>
    </div>
  );
}