#include <util/delay.h>

#include <arduino/pins.h>
#include <arduino/serial.h>

#define PIN_SCLK 2
#define PIN_CS 3
#define PIN_MOSI 4
#define PIN_MISO 5
#define PIN_ACK 6


static void
my_puts(const char *s)
{
  char c;

  while ((c = *s++))
  {
    while (!serial_writeable())
      ;
    serial_write(c);
  }
}


static void
init(void)
{
  serial_baud_115200();
  serial_mode_8n1();
  serial_transmitter_enable();
  serial_receiver_enable();

  pin_mode_output(PIN_SCLK);
  pin_mode_output(PIN_CS);
  pin_mode_output(PIN_MOSI);
  pin_mode_input(PIN_MISO);
  pin_mode_input(PIN_ACK);
  pin_high(PIN_CS);
  pin_high(PIN_SCLK);
}


static void
wait_for_ack(void)
{
  uint16_t i;

  for (i = 0; i < 60000; ++i)
  {
    if (!pin_is_high(PIN_ACK))
      break;
  }
  if (i == 60000)
    my_puts("TIMOUT\r\n");
}


static uint8_t
panel_send_byte(uint8_t b_out)
{
  uint8_t i;
  uint8_t b_in;

  pin_low(PIN_CS);
  wait_for_ack();

  b_in = 0;
  for (i = 0; i < 8; ++i)
  {
    if (b_out & 0x80)
      pin_high(PIN_MOSI);
    else
      pin_low(PIN_MOSI);
    pin_low(PIN_SCLK);
    _delay_us(5);
    b_in <<= 1;
    if (pin_is_high(PIN_MISO))
      b_in |= 1;
    pin_high(PIN_SCLK);
    _delay_us(5);
  }
  wait_for_ack();
  pin_high(PIN_CS);

  return b_in;
}


int
main()
{
  init();

  for (;;)
  {
    my_puts("Hello, World ");
    if (pin_is_high(PIN_ACK))
      my_puts("UP!\r\n");
    else
      my_puts("DOWN!\r\n");
    pin_low(PIN_SCLK);
    _delay_ms(500);
    pin_high(PIN_SCLK);
    _delay_ms(500);
  }
}
