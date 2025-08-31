import { NextRequest, NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  const token = request.cookies.get("token")?.value || localStorage.getItem("token");
  const user = localStorage.getItem("user");
  const isCompanyRoute = request.nextUrl.pathname.startsWith("/company");

  if (isCompanyRoute && (!token || !user)) {
    return NextResponse.redirect(new URL("/auth/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/company/:path*"],
};