`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 13:33:17
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(

    input clk,reset,
    output reg red,blue,green,
    output reg vsync,hsync
    );
    
    reg [3:0]p_c;
    reg p_clk;
    reg [9:0]h_c,v_c;
    
    reg[7:0] font;
    
    
    
    //pixel clock
    always @(posedge clk) begin
        if(reset)begin
            p_clk<=0;
            p_c<=0;
            
        end
        else begin
            
            if(p_c==4'd3)begin
                p_clk<=1;
                p_c<=0;
            end
            else begin
                p_clk<=0;
                p_c<=p_c+1;    
            end
        end
    end
    
    always@(posedge clk)begin
        if(reset)begin
            h_c<=0;v_c<=0;
            hsync<=1;
            vsync<=1;
        end
        else begin
            if(p_clk)begin
                if(h_c==10'd799)begin
                    h_c<=0;
                    if(v_c==10'd524)begin
                        v_c<=0;
                    end
                    else begin
                        v_c<=v_c+1;
                    end
                   
                end
                else begin
                     h_c<=h_c+1;
                end                
                if (h_c >= 10'd655 && h_c <= 10'd750) hsync <= 1'b0;
    
                else                                  hsync <= 1'b1;
        
                if (v_c >= 10'd489 && v_c <= 10'd490) vsync <= 1'b0;
                else                                  vsync <= 1'b1;
                 
            end
           
        end
    end
    wire video_on = (h_c < 640) && (v_c < 480);
    
    wire [4:0]h=h_c[9:5];
    wire [2:0]v=v_c[4:2];
    
    
    wire [7:0]word={v,h};
    
    always@(*)begin
        font=8'd0;
        case(word) 
        //D
        8'b00000000:  font=8'b11111100  ;
        8'b00100000:  font=8'b01100010  ;
        8'b01000000:  font=8'b01100001  ;
        8'b01100000:  font=8'b01100001  ;
        8'b10000000:  font=8'b01100001  ;
        8'b10100000:  font=8'b01100001  ;
        8'b11000000:  font=8'b01100010  ;
        8'b11100000:  font=8'b11111100  ;
        //h
        8'b00000001:  font=8'b01100110  ;
        8'b00100001:  font=8'b01100110  ;
        8'b01000001:  font=8'b01100110  ;
        8'b01100001:  font=8'b01111110  ;
        8'b10000001:  font=8'b01100110  ;
        8'b10100001:  font=8'b01100110  ;
        8'b11000001:  font=8'b01100110  ;
        8'b11100001:  font=8'b01100110  ;
        //A
        8'b00000010:  font=8'b00111100  ;
        8'b00100010:  font=8'b01100110  ;
        8'b01000010:  font=8'b01100110  ;
        8'b01100010:  font=8'b01111110  ;
        8'b10000010:  font=8'b01100110  ;
        8'b10100010:  font=8'b01100110  ;
        8'b11000010:  font=8'b01100110  ;
        8'b11100010:  font=8'b01100110  ;
        //Y
        8'b00000011:  font=8'b01100110  ;
        8'b00100011:  font=8'b01100110  ;
        8'b01000011:  font=8'b01100110  ;
        8'b01100011:  font=8'b00111100  ;
        8'b10000011:  font=8'b00011000  ;
        8'b10100011:  font=8'b00011000  ;
        8'b11000011:  font=8'b00011000  ;
        8'b11100011:  font=8'b00011000  ;
        

        endcase
    end 
    always@(*) begin
        // --- 1. DEFAULT VALUES (Prevents Latches) ---
     
        red     = 1'b0;
        green   = 1'b0;
        blue    = 1'b0;
        
        if (video_on) begin
                
                green = font[7 - h_c[4:2]]; // Directly selects the pixel bit
                red     = 1'b0;
                blue    = 1'b0;
               
        end
        else begin
            red   = 1'b0;
            green = 1'b0;
            blue  = 1'b0;
        end
    end
endmodule
