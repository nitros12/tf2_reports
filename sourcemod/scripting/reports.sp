/*

TF2 reports pusher, written by nitros: [https://github.com/nitros12]

*/
#include <sourcemod>
#include <SteamWorks>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1.1"

#define REPORT_MESSAGE "@here %L has issued a report with reason %s\n"
#define MAX_REQUEST_LENGTH 8192
#define MAX_MESSAGE_LEN 512

ConVar g_Webook_URL;

public Plugin myinfo = {
  name = "TF2Discord reports",
  author = "Nitros",
  description = "Pushes tf2 reports to discord",
  version = PLUGIN_VERSION,
  url = "ben@bensimms.moe"
};

public void OnPluginStart() {
  LoadTranslations("common.phrases");
  RegConsoleCmd("report", ReportCmd, "Send a report message.");

  g_Webook_URL = CreateConVar("sm_report_webhook", "", "Webhook to send reports to", FCVAR_PROTECTED,
               false, _, false, _);

  AutoExecConfig(true, "discord_reports");
}

public Action ReportCmd(int client, int argc) {
  if (argc < 1) {
    ReplyToCommand(client, "[SM] Usage: report <message>");
    return Plugin_Handled;
  }

  char message[MAX_MESSAGE_LEN];
  char report_message[MAX_REQUEST_LENGTH];
  GetCmdArgString(message, sizeof(message));

  Format(report_message, sizeof(report_message), REPORT_MESSAGE, client, message);
  // Create format message

  if (send_report(report_message)) PrintToChat(client, "Thanks for your report, we will get to it soon");
  return Plugin_Handled;
}

int send_report(const char[] message) {
  char url[500];
  char json_dump_data[MAX_REQUEST_LENGTH];
  json_dump_data[0] = '\0';
  GetConVarString(g_Webook_URL, url, sizeof(url));
  if (url[0] == '\0') {
    LogToGame("<Discord Reports> Error: Webhook url not set");
  }

  Handle json = json_object();
  if (json == INVALID_HANDLE) {
    LogToGame("<Discord Reports> Error could not create JSON object");
    return false;
  }

  json_object_set_new(json, "content", json_string(message));
  json_dump(json, json_dump_data, MAX_REQUEST_LENGTH, 0, true);
  delete json;

  Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);
  if (request == INVALID_HANDLE) {
    LogToGame("<Discord Reports> Error: Could not create http request");
    return false;
  }

  SteamWorks_SetHTTPRequestRawPostBody(request, "application/json; charset=UTF-8", json_dump_data, strlen(json_dump_data));
  SteamWorks_SendHTTPRequest(request);

  delete request;
  return true;
}
