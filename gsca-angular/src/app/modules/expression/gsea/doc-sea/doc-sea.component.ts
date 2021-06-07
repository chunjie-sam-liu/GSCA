import { Component, OnInit } from '@angular/core';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-doc-sea',
  templateUrl: './doc-sea.component.html',
  styleUrls: ['./doc-sea.component.css'],
})
export class DocSeaComponent implements OnInit {
  public assets = environment.assets;
  constructor() {}

  ngOnInit(): void {}
}
