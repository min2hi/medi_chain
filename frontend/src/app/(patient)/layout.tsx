import "../globals.css";
import { Navigation } from "@/components/layout/Navigation";
import { MainLayout } from "@/components/layout/MainLayout";
import { KeepAlivePinger } from "@/components/shared/KeepAlivePinger";
import { ErrorBoundary } from "@/components/shared/ErrorBoundary";
import { I18nProvider } from "@/i18n/I18nProvider";

export default function PatientLayout({ children }: { children: React.ReactNode }) {
  return (
    <I18nProvider>
      <KeepAlivePinger />
      <Navigation />
      <MainLayout>
        <ErrorBoundary>
          {children}
        </ErrorBoundary>
      </MainLayout>
    </I18nProvider>
  );
}
