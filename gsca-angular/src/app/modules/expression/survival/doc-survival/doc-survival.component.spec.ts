import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSurvivalComponent } from './doc-survival.component';

describe('DocSurvivalComponent', () => {
  let component: DocSurvivalComponent;
  let fixture: ComponentFixture<DocSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
