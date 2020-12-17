import { Component, OnInit } from '@angular/core';
import citations from 'src/app/shared/constants/citations';

@Component({
  selector: 'app-citation',
  templateUrl: './citation.component.html',
  styleUrls: ['./citation.component.css'],
})
export class CitationComponent implements OnInit {
  public citations = citations;
  constructor() {}

  ngOnInit(): void {}
}
