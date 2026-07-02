module SB_IO #(
    parameter [5:0] PIN_TYPE = 6'b000000,
    parameter PULLUP = 1'b0
) (
    inout  PACKAGE_PIN,
    input  OUTPUT_ENABLE,
    input  D_OUT_0,
    output D_IN_0
);
    // Emulación funcional de un buffer tri-estado.
    // Si OUTPUT_ENABLE es 1, sacamos el dato; si no, alta impedancia (Z).
    assign PACKAGE_PIN = OUTPUT_ENABLE ? D_OUT_0 : 1'bz;
    
    // La entrada siempre lee el estado del pin/cable.
    assign D_IN_0 = PACKAGE_PIN;

endmodule
