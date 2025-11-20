#!/usr/bin/env python3
import inkex

__version__ = "1.0.7"


def round_number(num, decimals=3):
    rounded = round(float(num), decimals)
    return int(rounded) if rounded.is_integer() else rounded


class ShapeProcessor:
    def __init__(self, element, options, svg):
        self.element = element
        self.path = None
        self.style = element.specified_style()
        self.ass_tags = {
            "an": 7,
            "bord": 0,
            "shad": 0,
            "fscx": 100,
            "fscy": 100,
            "pos": [0, 0],
        }
        self.options = options
        self.svg = svg
        # self.notes = []

    def create_ass_tags(self):
        """Create tags based on the attributes of the element."""

        if opacity := self.get_opacity("opacity"):
            self.ass_tags["alpha"] = opacity

        fill_color = self.get_color("fill")
        if fill_color:
            self.ass_tags["c"] = fill_color

            if fill_opacity := self.get_opacity("fill-opacity"):
                self.ass_tags["1a"] = fill_opacity
        else:
            self.ass_tags["1a"] = "&HFF&"

        stroke_color = self.get_color("stroke")
        stroke_width = self.get_stroke_width()
        if stroke_width and stroke_color:
            self.ass_tags["bord"] = stroke_width
            self.ass_tags["3c"] = stroke_color

            if stroke_opacity := self.get_opacity("stroke-opacity"):
                self.ass_tags["3a"] = stroke_opacity

        self.ass_tags["p"] = 1

    def get_opacity(self, attrib):
        """Extract the opacity attribute from the element and convert to ass hex"""

        opacity = float(self.style.get(attrib, 1.0))
        if opacity != 1.0:
            return f"&H{int((1 - opacity) * 255):02X}&"
        return False

    def get_color(self, attrib):
        """Extract the fill color attribute from the element."""

        color_attr = self.style(attrib)

        if color_attr is None:
            return False

        if isinstance(color_attr, inkex.LinearGradient):
            # Get first color of the gradient for now
            first_stop = color_attr.href.stops[0]
            fisrt_stop_style = first_stop.specified_style()
            color_str = fisrt_stop_style.get("stop-color")

            # # TODO: Add support for linear gradients.
            # # Retrieve gradient attributes
            # x1 = color_attr.get("x1", "0%")
            # y1 = color_attr.get("y1", "0%")
            # x2 = color_attr.get("x2", "100%")
            # y2 = color_attr.get("y2", "0%")
            # inkex.errormsg(f"x1: {x1}, y1: {y1}, x2: {x2}, y2: {y2}")
            # # Process stops
            # for stop in color_attr.href.stops:
            #     stop_style = stop.specified_style()
            #     color = stop_style.get("stop-color")
            #     opacity = stop_style.get("stop-opacity")
            #     offset = stop.attrib.get("offset")
            #     inkex.errormsg(f"color: {color}, opacity: {opacity}, offset: {offset}")

        # elif isinstance(color_attr, inkex.RadialGradient):
        #     inkex.utils.debug("It's radial gradient.")
        else:
            color_str = color_attr

        color = inkex.Color(color_str)
        return f"&H{color.blue:02X}{color.green:02X}{color.red:02X}&"

    def get_stroke_width(self):
        """Extract the stroke attribute from the element."""

        stroke_width = self.style.get("stroke-width")
        if not stroke_width:
            return False

        paint_order = self.style.get("paint-order", "normal")
        if paint_order == "normal":
            paint_order = "fill stroke markers"

        paint_order = paint_order.split()
        stroke_index = paint_order.index("stroke")
        fill_index = paint_order.index("fill")
        if self.options.stroke_preservation == "strict" and stroke_index > fill_index:
            inkex.errormsg(
                f'Error:\n\nThe stroke order of object "{self.element.get_id()}" has stroke above fill which will have wrong output in ASS.\nYou see this message because have chosen strict stroke preservation in the GUI.\n\nFor accurate output, either change stroke order in Inkscape to have fill above stroke or change the stroke preservation in GUI if you don\'t mind applying path effect to your object.'
            )
            exit()
        elif (
            self.options.stroke_preservation == "use_path_effects"
            and stroke_index > fill_index
        ):
            paint_order[stroke_index] = "fill"
            paint_order[fill_index] = "stroke"

            offset_param_dict = {
                "update_on_knot_move": "true",
                "attempt_force_join": "false",
                "miter_limit": "4",
                "offset": -float(stroke_width) * 0.5,
                "unit": "px",
                "linejoin_type": "round",
                "lpeversion": "1.3",
                "is_visible": "true",
                "effect": "offset",
            }
            effect = inkex.PathEffect()
            for key in offset_param_dict:
                effect.set(key, offset_param_dict[key])
            self.svg.defs.add(effect)
            self.element.set("inkscape:original-d", self.element.attrib["d"])
            self.element.set("inkscape:path-effect", effect.get_id(as_url=1))

            self.element.style.update(
                {
                    "paint-order": " ".join(paint_order),
                    "stroke-width": float(stroke_width) * 2,
                }
            )
            return round_number(float(stroke_width) * 2, 2)
        else:
            return round_number(float(stroke_width) * 0.5, 2)

    def handle_clip_path(self):
        """Process the clip-path attribute of the element if present."""

        clip_path = self.element.get("clip-path")
        if clip_path is None:
            return

        clip_path = clip_path[5:-1]  # Extract the ID between 'url(#' and ')'
        clip_elem = self.svg.getElementById(clip_path)
        self.ass_tags["clip"] = f"({self.convert_path(clip_elem.to_path_element())})"

    def convert_path(self, shape_elem=None):
        """Convert the path of the shape element to the ass format."""

        if shape_elem is None:
            shape_elem = self.element
        # Apply any transformations and viewBox scaling
        shape_elem.apply_transform()

        # Convert commands like A, S, Q, and T to cubic bezier
        elem = shape_elem.path.to_superpath().to_path()

        # Convert all commands to absolute positions
        elem = elem.to_absolute()

        viewBoxScale = self.svg.scale
        if viewBoxScale != 1:
            elem.scale(viewBoxScale, viewBoxScale, True)

        # After this, path will now contain only M, L, C, and Z commands
        path = []
        prev_cmd = None
        for idx, segment in enumerate(elem):
            cmd = (segment.letter).lower()
            if cmd == "z":
                continue
            cmd = "b" if cmd == "c" else cmd
            if cmd != prev_cmd:
                path.append(cmd)
                prev_cmd = cmd
            path.extend([round_number(num) for num in segment.args])

        return " ".join(map(str, path))

    def generate_lines(self):
        """Combine tags, clips, and path to generate final output lines."""

        tags = []
        for key, value in self.ass_tags.items():
            if isinstance(value, list):
                value_str = f"({value[0]},{value[1]})"
            else:
                value_str = str(value)
            tags.append(f"\\{key}{value_str}")
        tag_string = "{" + "".join(tags) + "}"

        line = ""
        match self.options.output_format:
            case "drawing":
                line = tag_string + self.path
            case "clip":
                line = "\\clip(" + self.path + ")"
            case "iclip":
                line = "\\iclip(" + self.path + ")"
            case "line":
                line = (
                    "Dialogue: 0,0:00:00.00,0:00:00.02,Default,,0,0,0,,"
                    + tag_string
                    + self.path
                )

        return line

    def process(self):
        """Perform all steps in sequence to process the shape element."""

        self.create_ass_tags()
        self.handle_clip_path()
        if self.element.TAG != "path":
            self.element = self.element.to_path_element()
        self.path = self.convert_path()
        return self.generate_lines()


class ProcessElements(inkex.EffectExtension):
    def add_arguments(self, pars):
        pars.add_argument("--output_format", type=str, help="types of output")
        pars.add_argument("--stroke_preservation", type=str, help="types of output")

    def process_element(self, element):
        """Processes a single SVG element, handling groups recursively."""

        if isinstance(element, inkex.Group):
            element.bake_transforms_recursively()  # Apply transformations to the group
            for child in element:
                self.process_element(child)  # Recurse into group elements
        elif isinstance(element, inkex.ShapeElement):
            if element.TAG in {
                "path",
                "rect",
                "circle",
                "ellipse",
                "line",
                "polyline",
                "polygon",
            }:
                processor = ShapeProcessor(element, self.options, self.svg)
                line = processor.process()
                print(line)

    def effect(self):
        # Loop through all elements in the SVG
        unnecessary = ["g", "defs", "svg", "metadata", "namedview"]
        for element in self.svg.descendants():
            if element.TAG in unnecessary:
                continue
            self.process_element(element)


if __name__ == "__main__":
    ProcessElements().run()
