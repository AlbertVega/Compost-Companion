#include "svc_rules.h"

bool svc_validate(float t, float h) {
  if (t < -40 || t > 125) return false;
  if (h < 0 || h > 100)   return false;
  return true;
}

AlertType svc_alert(float t, float h, float THI, float TLO, float HHI, float HLO) {
  if (t > THI) return ALERT_TEMP_HIGH;
  if (t < TLO) return ALERT_TEMP_LOW;
  if (h > HHI) return ALERT_RH_HIGH;
  if (h < HLO) return ALERT_RH_LOW;
  return ALERT_NONE;
}

bool svc_should_send(uint32_t now_s, uint32_t last_send_s, uint32_t send_interval_s,
                     uint16_t buf_count, uint16_t buf_cap) {
  bool timeToSend = ((now_s - last_send_s) >= send_interval_s);
  bool nearFull = (buf_count >= (uint16_t)(buf_cap - 4));
  return (buf_count > 0) && (timeToSend || nearFull);
}