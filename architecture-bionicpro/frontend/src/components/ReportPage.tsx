import React, { useState } from "react";
import { useKeycloak } from "@react-keycloak/web";

type ProsthesisReport = {
  prosthesisId: string;
  model: string;
  period: {
    from: string;
    to: string;
  };
  totalUsageSeconds: number;
  totalMovements: number;
  averageBatteryLevel: number;
  totalErrors: number;
};

type ReportResponse = {
  status: string;
  user: {
    username: string;
    fullName: string | null;
  };
  period: {
    from: string;
    to: string;
  };
  reports: ProsthesisReport[];
  totals: {
    totalUsageSeconds: number;
    totalMovements: number;
    totalErrors: number;
  };
};

const ReportPage: React.FC = () => {
  const { keycloak, initialized } = useKeycloak();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [report, setReport] = useState<ReportResponse | null>(null);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const preferredUsername = (
    keycloak.tokenParsed as { preferred_username?: string } | undefined
  )?.preferred_username;

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  const downloadReport = async () => {
    if (!keycloak?.token) {
      setError("Not authenticated");
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setReport(null);

      await keycloak.updateToken(30);

      const params = new URLSearchParams();
      if (fromDate) {
        params.set("from", fromDate);
      }
      if (toDate) {
        params.set("to", toDate);
      }

      const query = params.toString();
      const url = `${process.env.REACT_APP_API_URL}/reports${query ? `?${query}` : ""}`;

      const response = await fetch(url, {
        headers: {
          Authorization: `Bearer ${keycloak.token}`,
        },
      });

      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || "Failed to load report");
      }

      setReport(payload);
    } catch (err) {
      setError(err instanceof Error ? err.message : "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  if (!initialized) {
    return <div>Loading...</div>;
  }

  if (!keycloak.authenticated) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100">
        <button
          onClick={() => keycloak.login()}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Login
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 px-6 py-10">
      <div className="mx-auto max-w-5xl rounded-lg bg-white p-8 shadow-md">
        <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-bold">Usage Reports</h1>
            <p className="text-sm text-gray-600">
              Signed in as {preferredUsername || keycloak.subject}
            </p>
          </div>
          <button
            onClick={() => keycloak.logout()}
            className="self-start rounded bg-gray-200 px-4 py-2 text-gray-800 hover:bg-gray-300 sm:self-auto"
          >
            Logout
          </button>
        </div>

        <div className="mb-6 grid gap-4 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
          <label className="flex flex-col gap-1 text-sm font-medium text-gray-700">
            From
            <input
              type="date"
              value={fromDate}
              onChange={(event) => setFromDate(event.target.value)}
              className="rounded border border-gray-300 px-3 py-2"
            />
          </label>
          <label className="flex flex-col gap-1 text-sm font-medium text-gray-700">
            To
            <input
              type="date"
              value={toDate}
              onChange={(event) => setToDate(event.target.value)}
              className="rounded border border-gray-300 px-3 py-2"
            />
          </label>
          <button
            onClick={downloadReport}
            disabled={loading}
            className={`rounded bg-blue-500 px-4 py-2 text-white hover:bg-blue-600 ${
              loading ? "cursor-not-allowed opacity-50" : ""
            }`}
          >
            {loading ? "Loading Report..." : "Get Report"}
          </button>
        </div>

        {error && (
          <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
            {error}
          </div>
        )}

        {report && (
          <div className="mt-6 space-y-6">
            <div className="rounded border border-gray-200 p-4">
              <h2 className="text-lg font-semibold">
                {report.user.fullName || report.user.username}
              </h2>
              <p className="text-sm text-gray-600">
                Processed period: {report.period.from} - {report.period.to}
              </p>
              <div className="mt-4 grid gap-4 sm:grid-cols-3">
                <div className="rounded bg-gray-50 p-3">
                  <div className="text-sm text-gray-500">Usage</div>
                  <div className="text-xl font-semibold">
                    {formatDuration(report.totals.totalUsageSeconds)}
                  </div>
                </div>
                <div className="rounded bg-gray-50 p-3">
                  <div className="text-sm text-gray-500">Movements</div>
                  <div className="text-xl font-semibold">
                    {report.totals.totalMovements}
                  </div>
                </div>
                <div className="rounded bg-gray-50 p-3">
                  <div className="text-sm text-gray-500">Errors</div>
                  <div className="text-xl font-semibold">
                    {report.totals.totalErrors}
                  </div>
                </div>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead>
                  <tr className="border-b bg-gray-50">
                    <th className="p-3">Prosthesis</th>
                    <th className="p-3">Model</th>
                    <th className="p-3">Usage</th>
                    <th className="p-3">Movements</th>
                    <th className="p-3">Avg. Battery</th>
                    <th className="p-3">Errors</th>
                  </tr>
                </thead>
                <tbody>
                  {report.reports.map((item) => (
                    <tr key={item.prosthesisId} className="border-b">
                      <td className="p-3 font-medium">{item.prosthesisId}</td>
                      <td className="p-3">{item.model}</td>
                      <td className="p-3">
                        {formatDuration(item.totalUsageSeconds)}
                      </td>
                      <td className="p-3">{item.totalMovements}</td>
                      <td className="p-3">{item.averageBatteryLevel}%</td>
                      <td className="p-3">{item.totalErrors}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportPage;
