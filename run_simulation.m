function result = run_simulation(boardState, timeLimit)
% Inputs:
%   boardState - A struct from the JavaScript UI with 'connections' and 'knobs'.
%   timeLimit  - The current time window setting from the 'Time/Div' knob.

% --- Simulation Parameters ---
fs = 500000; % Sampling frequency
t = (0:1/fs:timeLimit-1/fs)';

% --- Data Structures ---
node_outputs = containers.Map('KeyType', 'char', 'ValueType', 'any');
connection_map = containers.Map('KeyType', 'char', 'ValueType', 'char');

% --- 1. Define All Signal Sources ---
% Fixed Sources
node_outputs('port_gnd1') = zeros(size(t));
node_outputs('port_gnd2') = zeros(size(t));
node_outputs('port_gnd3') = zeros(size(t));
node_outputs('port_5V') = 5 * ones(size(t));

% Corrected Analog Outputs: 4V pk-pk (2.0V amplitude)
node_outputs('port_2khz_sin') = 2.0 * sin(2 * pi * 2000 * t);
node_outputs('port_100khz_sin') = 2.0 * sin(2 * pi * 100000 * t);
node_outputs('port_100khz_cos') = 2.0 * cos(2 * pi * 100000 * t);

% Corrected Digital Outputs: TTL logic levels 0 to 5V
node_outputs('port_2khz_digital') = 5.0 * (square(2 * pi * 2000 * t, 50) > 0);
node_outputs('port_8khz_digital') = 5.0 * (square(2 * pi * 8000 * t, 50) > 0);
node_outputs('port_100khz_digital') = 5.0 * (square(2 * pi * 100000 * t, 50) > 0);

% Dynamic Source (Variable DC)
vdc_norm_val = 0.5;
if isfield(boardState.knobs, 'knob_vdc')
    vdc_norm_val = boardState.knobs.knob_vdc;
end
node_outputs('port_vdc') = (vdc_norm_val * 5) * ones(size(t)) - 2.5;

% --- 2. Build Connection Map from Board State ---
if isfield(boardState, 'connections')
    for i = 1:numel(boardState.connections)
        conn = boardState.connections{i};
        output_port = conn{1};
        input_port = conn{2};
        connection_map(input_port) = output_port;
    end
end

% --- 3. Iteratively Evaluate All Connected Modules ---
max_iterations = 15; % Safety break to prevent infinite loops
for iter = 1:max_iterations
    nodes_solved_this_pass = 0;

    % --- Module: Dual Analog Switch ---
    if ~isKey(node_outputs, 'port_dual_analog_switch_out')

        control1_signal = zeros(size(t));
        control2_signal = zeros(size(t));
        in1_signal = zeros(size(t));
        in2_signal = zeros(size(t));
        can_solve_switch = true;

        if isKey(connection_map, 'port_dual_analog_switch_control1')
            source_port = connection_map('port_dual_analog_switch_control1');
            if isKey(node_outputs, source_port), control1_signal = node_outputs(source_port); else, can_solve_switch = false; end
        end

        if isKey(connection_map, 'port_dual_analog_switch_control2')
            source_port = connection_map('port_dual_analog_switch_control2');
            if isKey(node_outputs, source_port), control2_signal = node_outputs(source_port); else, can_solve_switch = false; end
        end

        if isKey(connection_map, 'port_dual_analog_switch_in1')
            source_port = connection_map('port_dual_analog_switch_in1');
            if isKey(node_outputs, source_port), in1_signal = node_outputs(source_port); else, can_solve_switch = false; end
        end

        if isKey(connection_map, 'port_dual_analog_switch_in2')
            source_port = connection_map('port_dual_analog_switch_in2');
            if isKey(node_outputs, source_port), in2_signal = node_outputs(source_port); else, can_solve_switch = false; end
        end

        if can_solve_switch
            output_signal = zeros(size(t));
            output_signal(control1_signal > 0) = in1_signal(control1_signal > 0);
            output_signal(control2_signal > 0) = in2_signal(control2_signal > 0);
            node_outputs('port_dual_analog_switch_out') = output_signal;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Twin Pulse Generator ---
    if ~isKey(node_outputs, 'port_twin_pulse_q1') || ~isKey(node_outputs, 'port_twin_pulse_q2')

        clk_signal = zeros(size(t)); 
        can_solve_pulser = false; 

        if isKey(connection_map, 'port_twin_pulse_clk')
            source_port = connection_map('port_twin_pulse_clk');
            if isKey(node_outputs, source_port)
                clk_signal = node_outputs(source_port);
                can_solve_pulser = true; 
            end
        end

        if can_solve_pulser
            width_knob_pos = 0.5;
            if isfield(boardState.knobs, 'knob_twin_pulse_width')
                width_knob_pos = boardState.knobs.knob_twin_pulse_width;
            end

            delay_knob_pos = 0.5;
            if isfield(boardState.knobs, 'knob_twin_pulse_delay')
                delay_knob_pos = boardState.knobs.knob_twin_pulse_delay;
            end

            PULSE_WIDTH_RANGE = [5e-6, 40e-6];   
            PULSE_DELAY_RANGE = [50e-6, 300e-6]; 
            pulse_width_s = PULSE_WIDTH_RANGE(1) + width_knob_pos * (PULSE_WIDTH_RANGE(2) - PULSE_WIDTH_RANGE(1));
            pulse_delay_s = PULSE_DELAY_RANGE(1) + delay_knob_pos * (PULSE_DELAY_RANGE(2) - PULSE_DELAY_RANGE(1));

            rising_edges = (clk_signal > 0) & (circshift(clk_signal, 1) <= 0);
            rising_edge_indices = find(rising_edges);

            q1 = zeros(size(t));
            q2 = zeros(size(t));

            width_samples = round(pulse_width_s * fs);
            delay_samples = round(pulse_delay_s * fs);

            for i = 1:length(rising_edge_indices)
                start_index = rising_edge_indices(i);
                end_q1 = min(start_index + width_samples - 1, length(t));
                q1(start_index:end_q1) = 5; 
                
                start_q2 = start_index + delay_samples;
                end_q2 = min(start_q2 + width_samples - 1, length(t));
                if start_q2 <= length(t)
                    q2(start_q2:end_q2) = 5; 
                end
            end

            node_outputs('port_twin_pulse_q1') = q1;
            node_outputs('port_twin_pulse_q2') = q2;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Voltage-Controlled Oscillator (VCO) ---
    if ~isKey(node_outputs, 'port_vco_sin') 

        vco_input_voltage = zeros(size(t)); 
        can_solve_vco = true; 

        if isKey(connection_map, 'port_vco_input')
            source_port = connection_map('port_vco_input');
            if isKey(node_outputs, source_port)
                vco_input_voltage = node_outputs(source_port);
            else
                can_solve_vco = false; 
            end
        end

        if can_solve_vco
            VCO_FREQ_LO_RANGE = [1000, 17000];
            VCO_FREQ_HI_RANGE = [60000, 140000];
            VCO_INPUT_VOLTAGE_LIMITS = [-3, 3];
            VCO_GAIN_RANGE = [1, 2];

            vco_mode = 'lo';
            if isfield(boardState, 'vco') && isfield(boardState.vco, 'mode')
                vco_mode = lower(boardState.vco.mode);
            end
            freq_knob_position = 0.5;
            if isfield(boardState.knobs, 'knob_vco_freq'), freq_knob_position = boardState.knobs.knob_vco_freq; end
            gain_knob_position = 0.0;
            if isfield(boardState.knobs, 'knob_vco_gain'), gain_knob_position = boardState.knobs.knob_vco_gain; end
            gain_G = VCO_GAIN_RANGE(1) + gain_knob_position * (VCO_GAIN_RANGE(2) - VCO_GAIN_RANGE(1));

            vco_input_voltage = max(VCO_INPUT_VOLTAGE_LIMITS(1), min(VCO_INPUT_VOLTAGE_LIMITS(2), vco_input_voltage));

            if strcmp(vco_mode, 'hi'), active_range = VCO_FREQ_HI_RANGE; else, active_range = VCO_FREQ_LO_RANGE; end
            base_freq = active_range(1) + freq_knob_position * (active_range(2) - active_range(1));
            sensitivity_hz_per_volt = 1500;
            instantaneous_freq = base_freq + gain_G * vco_input_voltage * sensitivity_hz_per_volt;
            instantaneous_freq = max(active_range(1), min(active_range(2), instantaneous_freq));

            phase = 2 * pi * cumsum(instantaneous_freq) * (1/fs);

            % Corrected VCO output amplitude to match 4V pk-pk
            node_outputs('port_vco_sin') = 2.0 * sin(phase);
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Adder ---
    if ~isKey(node_outputs, 'port_adder_out') && isKey(connection_map, 'port_adder_A') && isKey(connection_map, 'port_adder_B')
        G = boardState.knobs.knob_adder_G;
        g = boardState.knobs.knob_adder_g;
        source_A = connection_map('port_adder_A');
        source_B = connection_map('port_adder_B');
        if isKey(node_outputs, source_A) && isKey(node_outputs, source_B)
            % Corrected logic: Implementing the inverting phase shift
            node_outputs('port_adder_out') = -(G * node_outputs(source_A) + g * node_outputs(source_B));
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Tunable Low-Pass Filter (LPF) ---
    if ~isKey(node_outputs, 'port_tunable_lpf_out') 

        lpf_input_signal = zeros(size(t)); 
        can_solve_lpf = true; 

        if isKey(connection_map, 'port_tunable_lpf_in')
            source_port = connection_map('port_tunable_lpf_in');
            if isKey(node_outputs, source_port)
                lpf_input_signal = node_outputs(source_port); 
            else
                can_solve_lpf = false; 
            end
        end

        if can_solve_lpf
            LPF_FC_RANGE = [600, 12000];    
            LPF_GAIN_RANGE = [0, 1.6];      
            FILTER_ORDER = 8;
            PASSBAND_RIPPLE = 0.5; 
            STOPBAND_ATTENUATION = 50; 

            fc_knob_position = 0.5;
            if isfield(boardState.knobs, 'knob_tunable_lpf_fc')
                fc_knob_position = boardState.knobs.knob_tunable_lpf_fc;
            end
            cutoff_freq_fc = LPF_FC_RANGE(1) + fc_knob_position * (LPF_FC_RANGE(2) - LPF_FC_RANGE(1));

            gain_knob_position = 0.5;
            if isfield(boardState.knobs, 'knob_tunable_lpf_gain')
                gain_knob_position = boardState.knobs.knob_tunable_lpf_gain;
            end
            filter_gain = LPF_GAIN_RANGE(1) + gain_knob_position * (LPF_GAIN_RANGE(2) - LPF_GAIN_RANGE(1));

            Wp = cutoff_freq_fc / (fs/2);
            [b, a] = ellip(FILTER_ORDER, PASSBAND_RIPPLE, STOPBAND_ATTENUATION, Wp);

            filtered_signal = filter(b, a, lpf_input_signal);
            lpf_analog_output = filtered_signal * filter_gain;

            node_outputs('port_tunable_lpf_out') = lpf_analog_output;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: BASEBAND LPF (Lowpass Filter) ---
    if ~isKey(node_outputs, 'port_baseband_lpf_out') 

        lpf_input_signal = zeros(size(t)); 
        can_solve_lpf = true;

        if isKey(connection_map, 'port_baseband_lpf_in') 
            source_port = connection_map('port_baseband_lpf_in');
            if isKey(node_outputs, source_port)
                lpf_input_signal = node_outputs(source_port);
            else
                can_solve_lpf = false; 
            end
        end

        if can_solve_lpf
            CUTOFF_FREQ = 1600; 
            FILTER_ORDER = 4;
            FILTER_GAIN = 0.9;

            Wn = CUTOFF_FREQ / (fs/2);
            [b, a] = butter(FILTER_ORDER, Wn, 'low');

            filtered_signal = filter(b, a, lpf_input_signal);
            lpf_output = filtered_signal * FILTER_GAIN;

            node_outputs('port_baseband_lpf_out') = lpf_output;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: CHANNEL BPF (Bandpass Filter) ---
    if ~isKey(node_outputs, 'port_channel_bpf_out') 

        bpf_input_signal = zeros(size(t)); 
        can_solve_bpf = true;

        if isKey(connection_map, 'port_channel_bpf_in') 
            source_port = connection_map('port_channel_bpf_in');
            if isKey(node_outputs, source_port)
                bpf_input_signal = node_outputs(source_port);
            else
                can_solve_bpf = false; 
            end
        end

        if can_solve_bpf
            F_CENTER = 100000; 
            PASSBAND_BW = 24000; 
            FILTER_ORDER = 6;
            PASSBAND_RIPPLE = 0.1; 
            FILTER_GAIN = 1.0;

            passband_edges = [F_CENTER - (PASSBAND_BW/2), F_CENTER + (PASSBAND_BW/2)];
            Wp = passband_edges / (fs/2);
            [b, a] = cheby1(FILTER_ORDER, PASSBAND_RIPPLE, Wp, 'bandpass');

            filtered_signal = filter(b, a, bpf_input_signal);
            bpf_output = filtered_signal * FILTER_GAIN;

            node_outputs('port_channel_bpf_out') = bpf_output;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Multiplier ---
    % --- Module: Multiplier 1 (Top-Left, AC/DC Coupled) ---
    if ~isKey(node_outputs, 'port_mult1_out')
        has_x = false; x_sig = zeros(size(t));
        has_y = false; y_sig = zeros(size(t));

        % Resolve X input (Prioritize DC if both are erroneously connected)
        if isKey(connection_map, 'port_mult1_x_dc') && isKey(node_outputs, connection_map('port_mult1_x_dc'))
            x_sig = node_outputs(connection_map('port_mult1_x_dc'));
            has_x = true;
        elseif isKey(connection_map, 'port_mult1_x_ac') && isKey(node_outputs, connection_map('port_mult1_x_ac'))
            x_raw = node_outputs(connection_map('port_mult1_x_ac'));
            x_sig = x_raw - mean(x_raw); % AC Coupling logic
            has_x = true;
        end

        % Resolve Y input
        if isKey(connection_map, 'port_mult1_y_dc') && isKey(node_outputs, connection_map('port_mult1_y_dc'))
            y_sig = node_outputs(connection_map('port_mult1_y_dc'));
            has_y = true;
        elseif isKey(connection_map, 'port_mult1_y_ac') && isKey(node_outputs, connection_map('port_mult1_y_ac'))
            y_raw = node_outputs(connection_map('port_mult1_y_ac'));
            y_sig = y_raw - mean(y_raw); % AC Coupling logic
            has_y = true;
        end

        if has_x && has_y
            node_outputs('port_mult1_out') = x_sig .* y_sig;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Multiplier 2 (Middle-Left, DC Only - Existing) ---
    if ~isKey(node_outputs, 'port_multiplier_DC_output') && isKey(connection_map, 'port_multiplier_DC_input_X') && isKey(connection_map, 'port_multiplier_DC_input_Y')
        source_X = connection_map('port_multiplier_DC_input_X');
        source_Y = connection_map('port_multiplier_DC_input_Y');
        if isKey(node_outputs, source_X) && isKey(node_outputs, source_Y)
            node_outputs('port_multiplier_DC_output') = node_outputs(source_X) .* node_outputs(source_Y);
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Multiplier 3 (Bottom-Right, DC Only) ---
    if ~isKey(node_outputs, 'port_mult3_out') && isKey(connection_map, 'port_mult3_x') && isKey(connection_map, 'port_mult3_y')
        source_X = connection_map('port_mult3_x');
        source_Y = connection_map('port_mult3_y');
        if isKey(node_outputs, source_X) && isKey(node_outputs, source_Y)
            node_outputs('port_mult3_out') = node_outputs(source_X) .* node_outputs(source_Y);
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Rectifier ---
    if ~isKey(node_outputs, 'port_rectifier_output') && isKey(connection_map, 'port_rectifier_input')
        source = connection_map('port_rectifier_input');
        if isKey(node_outputs, source)
            node_outputs('port_rectifier_output') = max(0, node_outputs(source));
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Diode + RC LPF (Envelope Detector) ---
    if ~isKey(node_outputs, 'port_diode_rc_lpf_output') && isKey(connection_map, 'port_diode_rc_lpf_input')
        source = connection_map('port_diode_rc_lpf_input');
        if isKey(node_outputs, source)
            rectified_signal = max(0, node_outputs(source));
            fc = 2.6e3;
            [b, a] = butter(1, fc/(fs/2));
            node_outputs('port_diode_rc_lpf_output') = filter(b, a, rectified_signal);
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: RC LPF ---
    if ~isKey(node_outputs, 'port_rc_lpf_output') && isKey(connection_map, 'port_rc_lpf_input')
        source = connection_map('port_rc_lpf_input');
        if isKey(node_outputs, source)
            fc = 2.6e3;
            [b, a] = butter(1, fc/(fs/2));
            node_outputs('port_rc_lpf_output') = filter(b, a, node_outputs(source));
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end
    % --- Module: Sequence Generator & Line Code Encoder ---
    if ~isKey(node_outputs, 'port_seq_x')
        clk_signal = zeros(size(t));
        can_solve_seq = true;

        if isKey(connection_map, 'port_seq_clk')
            source_port = connection_map('port_seq_clk');
            if isKey(node_outputs, source_port)
                clk_signal = node_outputs(source_port);
            else
                can_solve_seq = false;
            end
        end

        if can_solve_seq
            % Detect clock states
            clk_high = (clk_signal > 2.5);
            rising_edges = clk_high & (circshift(clk_signal, 1) <= 2.5);
            cycle_counts = cumsum(rising_edges);
            
            % PRBS Definitions
            prbs5 = [1; 0; 0; 0; 0; 1; 0; 0; 1; 0; 1; 1; 0; 0; 1; 1; 1; 1; 1; 0; 0; 0; 1; 1; 0; 1; 1; 1; 0; 1; 0];
            old_rng = rng; rng(1); prbs8 = randi([0, 1], 255, 1); rng(old_rng);
            
            x_indices = mod(cycle_counts, 31) + 1;
            y_indices = mod(cycle_counts, 255) + 1;
            
            % Digital Outputs
            node_outputs('port_seq_x') = prbs5(x_indices) * 5;
            node_outputs('port_seq_y') = prbs8(y_indices) * 5;
            node_outputs('port_seq_sync') = (x_indices == 1) * 5;
            
            % --- Line Code Precomputations ---
            % AMI: Alternate signs for every '1'
            ami_signs = ones(31, 1);
            ones_idx = find(prbs5 == 1);
            ami_signs(ones_idx(2:2:end)) = -1;
            ami_levels = prbs5 .* ami_signs; 
            
            % NRZ-M: Differential encoding (toggle on '1')
            nrz_m_bits = mod(cumsum(prbs5), 2);
            
            % --- Line Code Selection ---
            lc_mode = 'nrz-l';
            if isfield(boardState, 'line_code')
                lc_mode = lower(boardState.line_code);
            end
            
            switch lc_mode
                case 'nrz-l'
                    % 1 = +2V, 0 = -2V
                    node_outputs('port_seq_line_code') = (prbs5(x_indices) * 4) - 2; 
                    
                case 'bi-phase'
                    % Manchester: 1 = High to Low, 0 = Low to High
                    nrz_l = (prbs5(x_indices) * 4) - 2;
                    clk_polar = clk_high * 2 - 1; % 1 for first half, -1 for second half
                    node_outputs('port_seq_line_code') = nrz_l .* clk_polar;
                    
                case 'rz-ami'
                    % 1 = Alternating +/-2V for first half of bit, 0 for second half. 0 = 0V
                    node_outputs('port_seq_line_code') = ami_levels(x_indices) .* clk_high * 2;
                    
                case 'nrz-m'
                    % Toggle state on 1, hold state on 0
                    node_outputs('port_seq_line_code') = (nrz_m_bits(x_indices) * 4) - 2;
            end
            
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    % --- Module: Comparator (with Reference Input) ---
    if ~isKey(node_outputs, 'port_comparator_out') 

        input_signal = zeros(size(t));     
        reference_signal = zeros(size(t)); 
        can_solve_comparator = true;

        if isKey(connection_map, 'port_comparator_in')
            source_port = connection_map('port_comparator_in');
            if isKey(node_outputs, source_port)
                input_signal = node_outputs(source_port);
            else
                can_solve_comparator = false; 
            end
        end

        if isKey(connection_map, 'port_comparator_ref')
            ref_source_port = connection_map('port_comparator_ref');
            if isKey(node_outputs, ref_source_port)
                reference_signal = node_outputs(ref_source_port);
            else
                can_solve_comparator = false; 
            end
        end

        if can_solve_comparator
            node_outputs('port_comparator_out') = (input_signal > reference_signal) * 5;
            nodes_solved_this_pass = nodes_solved_this_pass + 1;
        end
    end

    if nodes_solved_this_pass == 0
        break;
    end
end

% --- 4. Prepare Final Output for Oscilloscope ---
result.time = t;
result.oscilloscope = struct('a', [], 'b', [], 'c', [], 'd', []);

for ch_cell = fieldnames(result.oscilloscope)'
    ch = ch_cell{1};
    osc_port_id = ['osc_ch_' ch];

    if isKey(connection_map, osc_port_id)
        source_port = connection_map(osc_port_id);
        if isKey(node_outputs, source_port)
            result.oscilloscope.(ch) = node_outputs(source_port);
        else
            result.oscilloscope.(ch) = zeros(size(t)); 
        end
    else
        result.oscilloscope.(ch) = zeros(size(t)); 
    end
end
end