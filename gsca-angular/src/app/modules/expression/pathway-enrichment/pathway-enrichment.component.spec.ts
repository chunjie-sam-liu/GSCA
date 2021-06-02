import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PathwayEnrichmentComponent } from './pathway-enrichment.component';

describe('PathwayEnrichmentComponent', () => {
  let component: PathwayEnrichmentComponent;
  let fixture: ComponentFixture<PathwayEnrichmentComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PathwayEnrichmentComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PathwayEnrichmentComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
